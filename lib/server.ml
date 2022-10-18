open Lwt
open Lwt.Syntax
open Lwt.Infix

let curr_connections = ref 0

let listen port =
  let localhost = Core_unix.Inet_addr.localhost in
  let server_socket = Sock_util.create_server_socket localhost port in
  Printf.printf "Listening on %s:%d"
    (Core_unix.Inet_addr.to_string localhost)
    port;
  Lwt_unix.of_unix_file_descr server_socket

(* Make this into a wrapper *)
let validate_connection conn =
  if !curr_connections < Sock_util.conn_limit then (
    incr curr_connections;
    return_ok conn)
  else return_error conn

let rec accept_conn_loop socket () =
  let* socket_fd, client_sockaddr = Lwt_unix.accept socket in
  let client_addr = Sock_util.sockaddr_to_string client_sockaddr in
  let* _ = Lwt_io.printlf "Connected to %s" client_addr in
  validate_connection socket_fd
  >>= (function
        | Error sock -> Sock_util.handle_connection sock Handler.reject_handler
        | Ok sock ->
            Sock_util.handle_connection sock Handler.chat_handler >|= fun _ ->
            decr curr_connections)
  <&> accept_conn_loop socket ()

let serve port =
  Lwt_main.run
    (let fd = listen port in
     accept_conn_loop fd ())
