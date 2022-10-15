open Websocket
open Lwt

let rtt_tbl = Hashtbl.create 10

let prep_message =
  let counter = ref 0 in
  fun () ->
    incr counter;
    Hashtbl.add rtt_tbl !counter (Time_unix.now ())

let get_rtt id =
  let curr = Time_unix.now () in
  let prev = Hashtbl.find rtt_tbl id in
  Time_unix.abs_diff curr prev

let recv_ack_f : Websocket.Frame.t -> unit = function
  | { opcode = Text; content; _ } as frame ->
      let msg_id = Scanf.sscanf content "%s %d %s" (fun _ id _ -> id) in
      let rtt = get_rtt msg_id |> Time_unix.Span.to_string_hum in
      Printf.printf "RTT : %s %s\n%!" rtt (Websocket.Frame.show frame)
  | _ -> failwith "Not implemented"

let send_message_f write =
  Lwt_io.(read_line_opt stdin) >>= function
  | Some content ->
      prep_message ();
      let frame = Websocket.Frame.create ~content () in
      write frame
  | None -> failwith "No inputs"

let make_response =
  let counter = ref 0 in
  fun () ->
    incr counter;
    let content = Printf.sprintf "Message %d Recieved!" !counter in
    Websocket.Frame.create ~content ()

let respond_rtt_f (write : Frame.t -> unit t) (frame : Websocket.Frame.t) =
  match frame with
  | { opcode = Text; content; _ } ->
      let fmt_msg = ">>> " ^ content in
      let _ = print_endline fmt_msg in
      write (make_response ())
  | _ -> failwith "Not implemented"
