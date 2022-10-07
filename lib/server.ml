open Core_unix
open Core
open! Lwt
open! Lwt.Syntax

module Config = struct
  let listen_address = Inet_addr.localhost
  let port = 9000
  let listen_sockaddr = ADDR_INET (listen_address, port)
  let backlog = 1

  let setup_socket sockaddr =
    let open Lwt_unix in
    (* Create socket for IO *)
    let socket = socket PF_INET SOCK_STREAM 0 in
    (* Bind sockaddr in config to socket *)
    let* _ = bind socket sockaddr in
    listen socket backlog;
    return socket
end

module Handler = struct
  type t = Lwt_io.input_channel -> Lwt_io.output_channel -> unit -> unit Lwt.t

  let _handle_message msg =
    match msg with
    | "exit" -> failwith "Close connection"
    | msg ->
        let id, msg =
          match String.lsplit2 msg ~on:' ' with
          | Some pair -> pair
          | None -> failwith ""
        in
        let fmt_msg = Printf.sprintf ">>> %s" msg in
        (id, fmt_msg)

  let rec handle_connection ic oc () =
    Lwt_io.read_line_opt ic >>= fun msg ->
    match msg with
    | Some msg ->
        let id, msg = _handle_message msg in
        print_endline msg;
        Lwt_io.write_line oc id >>= handle_connection ic oc
    | None -> Logs_lwt.info (fun m -> m "Connection closed") >>= return
end

(* Startup in listen mode *)
let run_server () =
  Printf.printf "Listening on %s:%d\n%!"
    (Config.listen_address |> Inet_addr.to_string)
    Config.port;
  let* socket = Config.(setup_socket listen_sockaddr) in

  let rec accept_conn_loop () =
    let* socket_fd, _client_sockaddr = Lwt_unix.accept socket in
    let ic = Lwt_io.of_fd ~mode:Lwt_io.Input socket_fd in
    let oc = Lwt_io.of_fd ~mode:Lwt_io.Output socket_fd in
    Handler.handle_connection ic oc () >>= accept_conn_loop
  in
  accept_conn_loop ()

let establish_server () =
  Printf.printf "Listening on %s:%d\n%!"
    (Config.listen_address |> Inet_addr.to_string)
    9001;
  let* socket =
    Config.(setup_socket @@ ADDR_INET (Inet_addr.localhost, 9001))
  in

  let rec accept_conn_loop () =
    let* socket_fd, _client_sockaddr = Lwt_unix.accept socket in
    let ic = Lwt_io.of_fd ~mode:Lwt_io.Input socket_fd in
    let oc = Lwt_io.of_fd ~mode:Lwt_io.Output socket_fd in
    Handler.handle_connection ic oc () >>= accept_conn_loop
  in
  accept_conn_loop ()

let listen () = Lwt_main.run (run_server ()) |> ignore
