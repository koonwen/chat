(* Utilities for creating Unix sockets, connecting and listening to IP
   addresses *)
open Unix

(** Number of {b complete} connections that are buffered, for this reason, to
    drop the connections, we need to build in logic after the accepting the
    connections to drop connections. Read `create_server_socket` docstring for
    more details *)
let conn_limit = 1

let new_socket () = socket PF_INET SOCK_STREAM 0

let get_sockaddr host port =
  let sockaddr = ADDR_INET (host, port) in
  sockaddr

let sockaddr_to_string sockaddr =
  let { ni_hostname; ni_service } = getnameinfo sockaddr [ NI_NUMERICHOST ] in
  ni_hostname ^ ":" ^ ni_service

(** Notes taken from https://ocaml.org/p/core/v0.12.3/doc/Core/Unix/index.html

    the [listen file_descr -> backlog:int -> unit] unix primitive is used here
    and sets up a socket for receiving connection requests. The integer argument
    is the number of pending requests that will be established and queued for
    accept. Depending on operating system, version, and configuration,
    subsequent connections may be refused actively (as with RST), ignored, or
    effectively established and queued anyway.

    Because handling of excess connections varies, it is most robust for
    applications to accept and close excess connections if they can. To be sure
    the client receives an RST rather than an orderly shutdown, you can
    setsockopt_optint file_descr SO_LINGER (Some 0) before closing.

    In Linux, for example, the system configuration parameters
    tcp_max_syn_backlog, tcp_abort_on_overflow, and syncookies can all affect
    connection queuing behavior. *)
let create_server_socket host port =
  let socket = new_socket () in
  try
    let sockaddr = get_sockaddr host port in
    setsockopt socket SO_REUSEADDR true;
    setsockopt_optint socket SO_LINGER (Some 5);
    bind socket sockaddr;
    listen socket conn_limit;
    socket
  with e ->
    close socket;
    raise e

let create_client_socket host port =
  let sockaddr = get_sockaddr host port in
  let socket = new_socket () in
  try
    connect socket sockaddr;
    socket
  with e ->
    close socket;
    raise e

(** Creates input and output streams and passes it to the [handler] *)
let handle_connection sock handler =
  (* let open Lwt in *)
  let open Lwt_io in
  let ic = of_fd ~mode:Input sock in
  let oc = of_fd ~mode:Output sock in
  handler ic oc

(** Installs SIGINT signal handler to ensure proper termination if CTRL-C is
    hit. Using the shutdown command also closes the input and output streams *)
let install_sigint sock =
  Lwt_unix.on_signal Sys.sigint (fun _ ->
      Printf.printf "\n[Interrupt] Close Connection\n%!";
      Unix.close sock;
      exit 0)