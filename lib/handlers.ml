open Lwt.Infix

module RTT = struct
  open Core
  open Core.Time_ns

  type t = Span.t

  let rtt_buffer_limit = 10
  let rtt_buffer = Array.create ~len:rtt_buffer_limit (now ())

  let id_gen max_id =
    let store = ref (-1) in
    fun () ->
      incr store;
      (* Reset index. Most likely messages were undelivered *)
      if Int.(!store >= max_id) then store := 0;
      !store

  let get_id = id_gen rtt_buffer_limit
  let reset_rtt id = rtt_buffer.(id) <- now ()

  let get_rtt (id : int) =
    if Int.(id <= -1 || id >= rtt_buffer_limit) then
      raise (Invalid_argument "RTT ID")
    else abs_diff (now ()) rtt_buffer.(id)

  let rtt_to_string = Span.to_string_hum

  let start_timer () =
    let id = get_id () in
    reset_rtt id;
    id
end

(* If user writes EOF [Ctrl-D] on stdin, this will stop the messaging and initiate a shutdown sequence for the connection *)
let read_send_loop _ic oc =
  let rec user_input () =
    Lwt_io.(read_line_opt stdin) >>= function
    | Some content -> set_rtt_and_send ~content
    | None -> Lwt.return_unit
  and set_rtt_and_send ~content =
    (* Start RTT timer and get ID for outgoing message *)
    let id = RTT.start_timer () in
    let packet = Serializer.make_packet ~id ~content Msg in
    Serializer.send oc packet >>= user_input
  in
  user_input ()

let recv_ack_msg_loop ic oc =
  let rec recv () =
    Lwt_io.read_line_opt ic >>= function
    | Some s -> Serializer.deserialize s |> react
    | None -> Lwt.return_unit
  and react { id; code; content } =
    match code with
    | Ack ->
        let rtt = RTT.get_rtt id in
        let rtt_string = rtt |> RTT.rtt_to_string in
        Lwt_io.printf "[RTT %s] %s\n" rtt_string content >>= recv
    | Msg ->
        Printf.printf ">>> %s\n%!" content;
        let content = "Message Recieved!" in
        let packet = Serializer.make_packet ~id ~content Ack in
        Serializer.send oc packet >>= recv
  in
  recv ()

let chat_handler ic oc =
  let requester = read_send_loop ic oc in
  let responder = recv_ack_msg_loop ic oc in
  Lwt.pick [ requester; responder ]
