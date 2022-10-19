open Lwt
open Lwt.Syntax
open Lwt.Infix

let curr_connections = ref 0

let listen port =
  let localhost = Core_unix.Inet_addr.localhost in
  let server_socket = SockUtil.create_server_socket localhost port in
  Printf.printf "Listening on %s:%d\n%!"
    (Core_unix.Inet_addr.to_string localhost)
    port;
  Lwt_unix.of_unix_file_descr server_socket

(* Make this into a wrapper *)
let validate_connection socket_fd client_sockaddr =
  if !curr_connections < SockUtil.conn_limit then (
    incr curr_connections;
    let client_addr = SockUtil.sockaddr_to_string client_sockaddr in
    Printf.printf "Connected to %s\n%!" client_addr;
    return_ok socket_fd)
  else return_error socket_fd

let rec accept_conn_loop socket () =
  let* socket_fd, client_sockaddr = Lwt_unix.accept socket in
  validate_connection socket_fd client_sockaddr
  >>= (function
        | Error sock -> SockUtil.handle_connection sock Handler.reject_handler
        | Ok sock ->
            SockUtil.handle_connection sock Handler.chat_handler >|= fun _ ->
            decr curr_connections)
  <&> accept_conn_loop socket ()

let serve port =
  Lwt_main.run
    (let fd = listen port in
     accept_conn_loop fd ())
