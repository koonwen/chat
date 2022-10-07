open Unix

let backlog = 1
let new_socket () = Unix.socket PF_INET SOCK_STREAM 0

let get_sockaddr host port =
  let sockaddr = ADDR_INET (host, port) in
  sockaddr

let create_listen_socket host port =
  let socket = new_socket () in
  let sockaddr = get_sockaddr host port in
  bind socket sockaddr;
  listen socket backlog;
  socket

let handle_connection socket_fd handler =
  let ic, oc =
    Lwt_io.(of_fd ~mode:Input socket_fd, of_fd ~mode:Output socket_fd)
  in
  handler ic oc
