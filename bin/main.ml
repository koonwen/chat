open Lib
open Lwt
open Lwt.Syntax

module Connect = struct
  open Client

  let connect host port =
    Lwt_main.run
      (let _ = Server.establish_server () in
       connect host port)
end

module Listen = struct
  open Server
  open Core_unix

  let connect_to_client = function
    | ADDR_INET (host, _) ->
        let port = 9001 in
        Printf.printf "Trying to connect to %s:%d\n%!"
          (Inet_addr.to_string host) port;
        Client.connect host port
    | _ -> failwith "Not implemented"

  let listen () =
    Lwt_main.run
      (Printf.printf "Listening on %s:%d\n%!"
         (Config.listen_address |> Inet_addr.to_string)
         Config.port;
       let* socket = Config.(setup_socket listen_sockaddr) in

       let rec accept_conn_loop () =
         let* socket_fd, client_sockaddr = Lwt_unix.accept socket in
         let _ = connect_to_client client_sockaddr in
         let ic = Lwt_io.of_fd ~mode:Lwt_io.Input socket_fd in
         let oc = Lwt_io.of_fd ~mode:Lwt_io.Output socket_fd in
         Handler.handle_connection ic oc () >>= accept_conn_loop
       in
       accept_conn_loop ())
end

let () = Cli.cli_wrapper ~connect:Connect.connect ~listen:Listen.listen
