open Lwt

let connect host port =
  Printf.printf "Establishing connection with %s:%d\n%!"
    (Core_unix.Inet_addr.to_string host)
    port;
  let client_socket = Sock_util.create_client_socket host port in
  print_endline "Connected!";
  client_socket

let start_chat host host_port =
  let fd = connect host host_port in
  Lwt_main.run
    (Lwt.catch
       (fun () -> Sock_util.handle_connection fd Handlers.handler)
       (function
         | Exit -> Unix.close fd |> return | _ -> Unix.close fd |> return))
