open Websocket_lwt_unix
open Websocket
open Lwt.Syntax
open! Lwt

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

let rec receive_messege conn () =
  read conn >>= fun f ->
  let msg_id = Scanf.sscanf f.content "%s %d %s" (fun _ id _ -> id) in
  let rtt = get_rtt msg_id |> Time_unix.Span.to_string_hum in
  Lwt_io.printf "RTT : %s %s\n%!" rtt (Websocket.Frame.show f)
  >>= receive_messege conn

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

let start_client () =
  (* Add in logic when process ends with Ctrl-C to shutdown connection and send
     close message *)
  Lwt_main.run
    (let uri = Uri.of_string "http://localhost:8000" in
     let* endpt = Resolver_lwt.resolve_uri ~uri Resolver_lwt_unix.system in
     let open Conduit_lwt_unix in
     let ctx = Lazy.force default_ctx in
     let* client = Conduit_lwt_unix.endp_to_client ~ctx endpt in
     let* conn = Websocket_lwt_unix.connect client uri in
     send_message conn () <?> receive_messege conn ());
  ()

let connect uri =
  let* endpt = Resolver_lwt.resolve_uri ~uri Resolver_lwt_unix.system in
  let open Conduit_lwt_unix in
  let ctx = Lazy.force default_ctx in
  let* client = Conduit_lwt_unix.endp_to_client ~ctx endpt in
  Websocket_lwt_unix.connect client uri
