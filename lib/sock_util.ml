(* Utilities for creating Unix sockets, connecting and listening to IP
   addresses *)
open Unix

(* Number of connections that are buffered *)
let backlog = 1
let new_socket () = socket PF_INET SOCK_STREAM 0

let get_sockaddr host port =
  let sockaddr = ADDR_INET (host, port) in
  sockaddr

let create_server_socket host port =
  let socket = new_socket () in
  let sockaddr = get_sockaddr host port in
  bind socket sockaddr;
  listen socket backlog;
  socket

let create_client_socket host port =
  let sockaddr = get_sockaddr host port in
  let socket = new_socket () in
  connect socket sockaddr;
  socket

let handle_connection socket_fd handler =
  let lwt_fd = Lwt_unix.of_unix_file_descr socket_fd in
  let ic = Lwt_io.(of_fd ~mode:Input lwt_fd) in
  let oc = Lwt_io.(of_fd ~mode:Output lwt_fd) in
  handler ic oc
