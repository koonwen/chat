open Lwt.Infix

let connect host port =
  Printf.printf "Establishing connection with %s:%d ...\n%!"
    (Core_unix.Inet_addr.to_string host)
    port;
  let client_sock = SockUtil.create_client_socket host port in
  SockUtil.install_sigint client_sock |> ignore;
  let lwt_client_sock = Lwt_unix.of_unix_file_descr client_sock in
  Printf.printf "Connected!\n%!";
  SockUtil.handle_connection lwt_client_sock Handlers.chat_handler >>= fun _ ->
  Printf.printf "\nConnection Dropped\n%!";
  Lwt_unix.close lwt_client_sock

let start_chat host host_port = Lwt_main.run (connect host host_port)
