open Websocket_lwt_unix
open Websocket
open Lwt

let rtt_tbl = Hashtbl.create 10

(* Make this a wrapper over the message *)
let prep_message =
  let counter = ref 0 in
  fun () ->
    incr counter;
    Hashtbl.add rtt_tbl !counter (Time_unix.now ())

let get_rtt id =
  let curr = Time_unix.now () in
  let prev = Hashtbl.find rtt_tbl id in
  Time_unix.abs_diff curr prev

let rec recv_ack conn () =
  read conn >>= function
  | { opcode = Text; content; _ } as frame ->
      let msg_id = Scanf.sscanf content "%s %d %s" (fun _ id _ -> id) in
      let rtt = get_rtt msg_id |> Time_unix.Span.to_string_hum in
      Lwt_io.printf "RTT : %s %s\n%!" rtt (Websocket.Frame.show frame)
      >>= recv_ack conn
  | _ -> Lwt.fail_with "Not implemented"

let rec send_message conn () =
  Lwt_io.(read_line_opt stdin) >>= function
  | Some content ->
      prep_message ();
      let frame = Websocket.Frame.create ~content () in
      write conn frame >>= send_message conn
  | None ->
      write conn (Frame.create ~opcode:Close ()) >>= fun _ ->
      Websocket_lwt_unix.close_transport conn >>= fun _ ->
      Lwt_io.printl "Connection Terminated"
