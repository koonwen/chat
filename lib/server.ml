let make_response =
  let counter = ref 0 in
  fun () ->
    incr counter;
    let content = Printf.sprintf "Message %d Recieved!" !counter in
    Websocket.Frame.create ~content ()

let message_handler_f write (frame : Websocket.Frame.t) =
  match frame with
  | { opcode = Text; content; _ } ->
      let fmt_msg = ">>> " ^ content in
      let _ = print_endline fmt_msg in
      write (make_response ())
  | { opcode = Close; _ } -> Lwt_io.printl "Connection terminated"
  | _ -> failwith "Not implemented"
