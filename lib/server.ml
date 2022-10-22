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

(* We want to limit the number of connections that can chat with our server to one. However, the behaviour of how pending connections are handled is OS dependent, for linux and mac the connection is not refused but set to an 'incomplete' state. The workaround here is to not block the server from processing the next incoming connection request. Instead, we keep an internal counter that will validate if the number of connections live on the server exceeds the limit specified in SockUtils. Drops the connection if true. *)
let rec accept_conn_loop socket () =
  let* sock, client_sockaddr = Lwt_unix.accept socket in
  validate_connection client_sockaddr
  >>= (function
        | Error _ -> Lwt_unix.close sock
        | Ok _ ->
            SockUtil.handle_connection sock Handlers.chat_handler >>= fun _ ->
            Lwt_unix.close sock >|= fun _ ->
            decr curr_connections;
            Printf.printf
              "\nConnection Dropped\nWaiting for another connection\n%!")
  <&> accept_conn_loop socket ()

let listen port =
  let localhost = Core_unix.Inet_addr.localhost in
  let server_socket = SockUtil.create_server_socket localhost port in
  SockUtil.install_sigint server_socket |> ignore;
  Printf.printf "Listening on %s:%d\n%!"
    (Core_unix.Inet_addr.to_string localhost)
    port;
  let lwt_server_socket = Lwt_unix.of_unix_file_descr server_socket in
  accept_conn_loop lwt_server_socket ()

let serve port = Lwt_main.run (listen port)
