open Lwt.Syntax
open Lwt.Infix

module RTT = struct
  open Core
  open Core.Time_ns

  type t = Span.t

  let rtt_buffer_limit = 10
  let rtt_buffer = Array.create ~len:rtt_buffer_limit (now ())

  let id_gen =
    let store = ref (-1) in
    fun () ->
      (* Reset index. Most likely messages were undelivered *)
      if Int.(!store >= rtt_buffer_limit) then store := -1;
      incr store;
      !store

  let get_id = id_gen
  let reset_rtt id = rtt_buffer.(id) <- now ()
  let get_rtt id = abs_diff (now ()) rtt_buffer.(id)
  let rtt_to_string = Span.to_string_hum
end

exception ClientClose
exception ServerDrop

let rec chat_send _ic oc () =
  let user_input () =
    Lwt_io.(read_line_opt stdin) >>= function
    | Some content ->
        let id = RTT.get_id () in
        let packet = Serializer.make_packet ~id ~content Msg in
        (* Start the timer for this message *)
        RTT.reset_rtt id;
        Serializer.send oc packet
    | None ->
        let packet = Serializer.make_packet Close in
        Serializer.send oc packet
  in
  user_input () >>= chat_send _ic oc

let rec chat_recv ic oc () =
  let react ({ id; code; content } : Serializer.packet) =
    match code with
    | Ack ->
        let rtt = RTT.get_rtt id in
        let rtt_string = rtt |> RTT.rtt_to_string in
        Lwt_io.printf "[RTT %s] %s\n" rtt_string content
    | Msg ->
        let* _ = Lwt_io.printf ">>> %s\n" content in
        let content = "Message Recieved!" in
        let packet = Serializer.make_packet ~id ~content Ack in
        Serializer.send oc packet
    | Close ->
        let packet = Serializer.make_packet CloseAck in
        let* _ = Serializer.send oc packet in
        raise ServerDrop
    | CloseAck -> raise ClientClose
    | Reject -> raise ClientClose
  in
  Serializer.recv ic >>= react >>= chat_recv ic oc

let chat_handler ic oc close_fd =
  let p () =
    let t1 = chat_recv ic oc () in
    let t2 = chat_send ic oc () in
    t1 <?> t2
  in
  let f = function
    | ClientClose ->
        let* _ = close_fd () in
        let* _ = Lwt_io.printl "Connection Terminated" in
        exit 0
    | ServerDrop ->
        let* _ =
          Lwt_io.printl "Connection Dropped\nWaiting for new connection..."
        in
        Lwt.return_unit
    | e ->
        Printexc.print_backtrace stdout;
        Printexc.to_string_default e |> print_endline;
        Lwt.return_unit
  in
  Lwt.catch p f

let reject_handler _ic oc _close_fd =
  let packet = Serializer.make_packet Reject in
  Serializer.send oc packet
