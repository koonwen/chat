open Lwt

let listen port =
  let local_host = Core_unix.Inet_addr.localhost in
  let server_socket = Sock_util.create_server_socket local_host port in
  Printf.printf "Listening on %s:%d\n%!"
    (Core_unix.Inet_addr.to_string local_host)
    port;
  server_socket

let rec accept_conn_loop socket () =
  let socket_fd, _ = Unix.accept socket in
  Sock_util.handle_connection socket_fd Handlers.handler >>= fun _ ->
  accept_conn_loop socket ()

let serve () =
  let port = 9000 in
  let fd = listen port in
  Lwt_main.run (accept_conn_loop fd ())
