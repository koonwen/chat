open Chat
open Lwt
open Lwt.Syntax
open Websocket_lwt_unix

let rec respond_rtt conn () =
  let write = write conn in
  read conn >|= Client.respond_rtt_f write >>= fun _ -> respond_rtt conn ()

let rec send_message conn () =
  let write = write conn in
  Client.send_message_f write >>= send_message conn

let rec recv_ack conn () = read conn >|= Client.recv_ack_f >>= recv_ack conn

let rec message_handler conn =
  let write = write conn in
  read conn >>= Server.message_handler_f write >>= fun _ -> message_handler conn

let connect uri =
  let* client = Util.resolve_client_uri ~uri in
  (* Client Messenger logic *)
  let* conn1 = Websocket_lwt_unix.connect client uri in
  (* Server Reciever logic *)
  let* conn2 = Websocket_lwt_unix.connect client uri in
  send_message conn1 () <?> recv_ack conn1 () <?> message_handler conn2

let () =
  let uri = "http://127.0.0.1:8000" |> Uri.of_string in
  Lwt_main.run (connect uri)
