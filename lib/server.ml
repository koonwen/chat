open Lwt
open Lwt.Syntax

let listen port =
  let localhost = Core_unix.Inet_addr.localhost in
  let server_socket = Sock_util.create_server_socket localhost port in
  let* _ =
    Lwt_io.printlf "Listening on %s:%d"
      (Core_unix.Inet_addr.to_string localhost)
      port
  in
  return server_socket

let rec accept_conn_loop socket () =
  let socket_fd, client_sockaddr = Unix.accept socket in
  let socket_fd = Lwt_unix.of_unix_file_descr ~blocking:true socket_fd in
  let client_addr = Sock_util.sockaddr_to_string client_sockaddr in
  let* _ = Lwt_io.printlf "Connected to %s" client_addr in
  Sock_util.handle_connection socket_fd Handler.handler
  >>= accept_conn_loop socket

let serve port =
  Lwt_main.run
    (let* fd = listen port in
     accept_conn_loop fd ())
