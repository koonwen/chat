open Lib
open Lwt
open Lwt.Syntax
open Unix

module Connect = struct
  let validate_client host client_sockaddr =
    let ( = ) = Core_unix.Inet_addr.( = ) in
    match client_sockaddr with
    | ADDR_INET (client, _) -> host = client
    | _ -> false

  (* Start listening before connecting *)
  let listener host port =
    let sock =
      Util.create_listen_socket host port |> Lwt_unix.of_unix_file_descr
    in
    Printf.printf "Listening on %s:%d\n%!"
      (Core_unix.Inet_addr.to_string host)
      port;
    let rec accept_validate_loop () =
      let* socket_fd, client_sockaddr = Lwt_unix.accept sock in
      if validate_client host client_sockaddr then
        Server.(handle_connection socket_fd Handler.message_handler)
      else accept_validate_loop ()
    in
    accept_validate_loop ()

  let connect host port =
    Printf.printf "Establishing connection with %s:%d\n%!"
      (Core_unix.Inet_addr.to_string host)
      port;
    let socket = Util.new_socket () in
    let sockaddr = Util.get_sockaddr host port in
    connect socket sockaddr;
    print_endline "Connected!";
    let socket_lwt = Lwt_unix.of_unix_file_descr socket in
    Client.(handle_connection socket_lwt message_handler)

  let start_chat host host_port listen_port =
    Lwt_main.run
      (let _ = listener host listen_port in
       connect host host_port)
end

module Listen = struct
  let get_addr_port = function
    | ADDR_INET (addr, port) -> (addr, port)
    | _ -> failwith "Unimplemented"

  let listener host port =
    let sock =
      Util.create_listen_socket host port |> Lwt_unix.of_unix_file_descr
    in
    Printf.printf "Listening on %s:%d\n%!"
      (Core_unix.Inet_addr.to_string host)
      port;
    let rec accept_validate_loop () =
      let* socket_fd, client_sockaddr = Lwt_unix.accept sock in
      let client_addr, client_port = get_addr_port client_sockaddr in
      Printf.printf "Connected to %s:%d\n%!"
        (Core_unix.Inet_addr.to_string client_addr)
        client_port;
      let _ = Client.connect client_addr 9001 in
      Server.(handle_connection socket_fd Handler.message_handler)
      >>= accept_validate_loop
    in
    accept_validate_loop ()

  let listen () =
    let host = Core_unix.Inet_addr.localhost in
    let port = 9000 in
    Lwt_main.run (listener host port)
end

let () = Cli.cli_wrapper ~connect:Connect.start_chat ~listen:Listen.listen
