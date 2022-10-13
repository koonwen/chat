open Lwt.Syntax
open Lwt.Infix
open Chat
open Websocket_lwt_unix

let _ = Lwt_log.(add_rule "wschat*" Info)
let section = Lwt_log.Section.make "wschat"

let read_client_and_connect conn_client =
  let uri = Server.get_server_uri conn_client in
  let* client = Util.resolve_client_uri ~uri in
  let* conn = connect client uri in
  let* _ =
    Lwt_log.info_f ~section "Successfully created client connection to %s"
      (uri |> Uri.to_string)
  in
  Client.(send_message conn () <?> recv_ack conn ())

let accept_conn_loop conn_client =
  let* _ = Lwt_log.info ~section "Client connected!" in
  let open Server in
  let _ = read_client_and_connect conn_client in
  message_handler conn_client

let listen ~uri =
  let* server = Util.resolve_server_uri ~uri in
  let* _ = Lwt_log.info_f ~section "Listening on %s" (uri |> Uri.to_string) in
  establish_standard_server ~mode:server accept_conn_loop

let () =
  let uri = "http://127.0.01:8000" |> Uri.of_string in
  Lwt_main.run (listen ~uri)
