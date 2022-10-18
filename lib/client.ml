open Lwt
open Lwt.Syntax

let connect host port =
  let* _ =
    Lwt_io.printlf "Establishing connection with %s:%d ..."
      (Core_unix.Inet_addr.to_string host)
      port
  in
  let client_socket = Sock_util.create_client_socket host port in
  let* _ = Lwt_io.printl "Connected!" in
  return client_socket

let start_chat host host_port =
  Lwt_main.run
    (let* fd = connect host host_port in
     let fd = Lwt_unix.of_unix_file_descr ~blocking:true fd in
     Sock_util.handle_connection fd Handler.chat_handler)
