open Lwt.Infix

let connect sockaddr =
  Printf.printf "\nEstablishing connection with %s ...\n%!"
  @@ SockUtil.sockaddr_to_string sockaddr;
  let client_sock = SockUtil.create_client_socket sockaddr in
  SockUtil.install_sigint client_sock |> ignore;
  let lwt_client_sock = Lwt_unix.of_unix_file_descr client_sock in
  Printf.printf "Connected!\n%!";
  SockUtil.handle_connection lwt_client_sock Handlers.chat_handler >>= fun _ ->
  Printf.printf "\nConnection Dropped\n%!";
  Lwt_unix.close lwt_client_sock

let start_chat host port =
  let sockaddr =
    try SockUtil.get_sockaddr host port
    with e ->
      print_endline @@ Printexc.to_string_default e;
      exit 1
  in
  Lwt_main.run (connect sockaddr)
