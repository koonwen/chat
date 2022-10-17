open Lwt.Infix

module RTT = struct
  type t = Core.Time_ns.Span.t

  let rtt_buffer_limit = 10
  let rtt_buffer = Array.make rtt_buffer_limit (Core.Time_ns.now ())

  let id_gen =
    let store = ref (-1) in
    fun () ->
      (* Reset index. Most likely messages were undelivered *)
      if !store >= rtt_buffer_limit then store := -1;
      incr store;
      !store

  let get_rtt id = Core.Time_ns.(abs_diff (now ()) rtt_buffer.(id))
  let rtt_to_string = Core.Time_ns.Span.to_string_hum
  let get_id = id_gen
end

module Message = struct
  (* Convenience message type derived from packet data *)

  type message = Ack of (RTT.t * string) | Msg of string | Resp of string

  let recv_message ic =
    Serializer.on_recv ic >|= fun ({ id; flag; content } : Serializer.packet) ->
    if flag then
      let rtt = RTT.get_rtt id in
      Ack (rtt, content)
    else Msg content

  let send_message oc msg =
    let open RTT in
    let id = get_id () in
    rtt_buffer.(id) <- Core.Time_ns.now ();
    let packet : Serializer.packet =
      match msg with
      | Msg msg -> { id; flag = false; content = msg }
      | Resp msg -> { id; flag = true; content = msg }
      | _ -> failwith "Ack on send"
    in
    Serializer.to_send oc packet
end

let rec chat_send _ic oc () =
  let user_input () =
    Lwt_io.(read_line_opt stdin) >|= function
    | Some msg -> Message.Msg msg
    | None -> failwith ""
  in
  user_input () >>= Message.send_message oc >>= chat_send _ic oc

let rec chat_recv ic oc () =
  let open Message in
  let react = function
    | Ack (rtt, msg) ->
        let rtt_string = rtt |> RTT.rtt_to_string in
        Lwt_io.printf "[RTT %s] %s\n" rtt_string msg
    | Msg msg ->
        let fmt_msg = Printf.sprintf ">>> %s" msg in
        Lwt_io.printl fmt_msg >>= fun _ ->
        let message = Resp "Message Recived" in
        send_message oc message
    | _ -> failwith "[chat_recv] got constructor 'Resp'"
  in
  Message.recv_message ic >>= react >>= chat_recv ic oc

let handler ic oc =
  let t1 = chat_recv ic oc () in
  let t2 = chat_send ic oc () in
  t1 <?> t2
