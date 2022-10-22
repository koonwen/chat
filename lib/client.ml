open Lwt.Infix

let connect host port =
  Printf.printf "Establishing connection with %s:%d ...\n%!"
    (Core_unix.Inet_addr.to_string host)
    port;
  let client_socket =
    SockUtil.create_client_socket host port |> Lwt_unix.of_unix_file_descr
  in
  Printf.printf "Connected!\n%!";
  SockUtil.handle_connection client_socket Handlers.chat_handler >|= fun _ ->
  Lwt_unix.shutdown client_socket SHUTDOWN_ALL

let start_chat host host_port = Lwt_main.run (connect host host_port)
