open Lwt
open Lwt.Syntax
open Lwt.Infix

let curr_connections = ref 0

let validate_connection client_sockaddr =
  if !curr_connections < SockUtil.conn_limit then (
    incr curr_connections;
    let client_addr = SockUtil.sockaddr_to_string client_sockaddr in
    Printf.printf "Connected to %s\n%!" client_addr;
    return_ok ())
  else return_error ()

let rec accept_conn_loop socket () =
  let* sock, client_sockaddr = Lwt_unix.accept socket in
  validate_connection client_sockaddr
  >>= (function
        | Error _ -> Lwt_unix.shutdown sock SHUTDOWN_ALL |> return
        | Ok _ ->
            SockUtil.handle_connection sock Handlers.chat_handler >|= fun _ ->
            Lwt_unix.shutdown sock SHUTDOWN_ALL;
            decr curr_connections;
            Printf.printf
              "\nConnection Dropped\nWaiting for another connection\n%!")
  <&> accept_conn_loop socket ()

let listen port =
  let localhost = Core_unix.Inet_addr.localhost in
  let server_socket =
    SockUtil.create_server_socket localhost port |> Lwt_unix.of_unix_file_descr
  in
  Printf.printf "Listening on %s:%d\n%!"
    (Core_unix.Inet_addr.to_string localhost)
    port;
  accept_conn_loop server_socket ()

let serve port = Lwt_main.run (listen port)
