open Lwt
open Lwt.Syntax

let connect host port =
  Printf.printf "Establishing connection with %s:%d ...\n%!"
    (Core_unix.Inet_addr.to_string host)
    port;
  let client_socket = SockUtil.create_client_socket host port in
  Printf.printf "Connected!\n%!";
  Lwt_unix.of_unix_file_descr client_socket

let start_chat host host_port =
  Lwt_main.run
    (let fd = connect host host_port in
     SockUtil.handle_connection fd Handler.chat_handler)
