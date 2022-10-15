open Chat
open Lwt
open Lwt.Syntax
open Websocket_lwt_unix

type conn_op = Connected_client.t Option.t
type conn_pair = conn_op * conn_op

let connection_limit = ref 1

let conn_table : (Ipaddr.t, conn_pair) Hashtbl.t ref =
  ref (Hashtbl.create !connection_limit)

let rec message_handler client =
  let write = Connected_client.send client in
  Connected_client.recv client >>= Server.message_handler_f write >>= fun _ ->
  message_handler client

let rec recv_ack client =
  Connected_client.recv client >|= Client.recv_ack_f >>= fun _ ->
  recv_ack client

let rec send_message client =
  let write = Connected_client.send client in
  Client.send_message_f write >>= fun _ -> send_message client

let reject_connection conn =
  let reject_msg =
    Websocket.Frame.create ~opcode:Websocket.Frame.Opcode.Close
      ~content:"Connection Rejected" ()
  in
  Connected_client.send conn reject_msg

let accept_connection_loop conn =
  let source_ip = Connected_client.source conn |> Util.get_ip in
  match Hashtbl.find_opt !conn_table source_ip with
  | None ->
      if Hashtbl.length !conn_table > !connection_limit then
        reject_connection conn
      else (
        (* Server logic *)
        incr connection_limit;
        Hashtbl.add !conn_table source_ip (Some conn, None);
        message_handler conn)
  | Some (s_conn, c_conn) when c_conn |> Option.is_none ->
      (* Client logic *)
      Hashtbl.replace !conn_table source_ip (s_conn, Some conn);
      send_message conn <?> recv_ack conn
  | _ -> reject_connection conn

let listen uri =
  let* server = Util.resolve_server_uri ~uri in
  Websocket_lwt_unix.establish_standard_server ~mode:server
    accept_connection_loop

let () =
  let uri = "http://127.0.0.1:8000" |> Uri.of_string in
  Lwt_main.run (listen uri)
