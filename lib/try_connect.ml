open! Websocket_lwt_unix
open Websocket
open Lwt.Syntax
open! Lwt

let rec receive_messege conn () =
  read conn >>= fun f ->
  Lwt_io.printf "%s\n%!" (Websocket.Frame.show f) >>= receive_messege conn

let rec send_message conn () =
  Lwt_io.(read_line_opt stdin) >>= function
  | Some content ->
      let frame = Websocket.Frame.create ~content () in
      write conn frame >>= send_message conn
  | None ->
      write conn (Frame.create ~opcode:Close ()) >>= fun _ ->
      Websocket_lwt_unix.close_transport conn >>= fun _ ->
      Lwt_io.printl "Connection Terminated"

let () =
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
