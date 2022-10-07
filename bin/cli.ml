open Cmdliner
open Core_unix

(* Inet CLI converter *)
let inet_conv =
  let parse str =
    try Ok (Inet_addr.of_string str) with Failure e -> Error e
  in
  let print fmt ppf = Format.fprintf fmt "%s" @@ Inet_addr.to_string ppf in
  Arg.conv' (parse, print)

let subcommand_connect f =
  (* Server Parameter *)
  let host =
    let doc = "HOST to connect to" in
    Arg.(
      value & pos 1 inet_conv Inet_addr.localhost & info [] ~docv:"HOST" ~doc)
  in

  let host_port =
    let doc = "HOST port number" in
    Arg.(value & pos 2 int 9000 & info [] ~docv:"HOST_PORT" ~doc)
  in

  let listen_port =
    let doc = "Port for recieving messages from host" in
    Arg.(value & pos 3 int 9001 & info [] ~docv:"LISTEN_PORT" ~doc)
  in

  let doc =
    "Attempt to connect to HOST:HOST_PORT to initiate chat. Also open another \
     separate LISTEN_PORT to run a server to listen and recieve messages from \
     the HOST"
  in
  Cmd.v (Cmd.info ~doc "connect")
    Term.(const f $ host $ host_port $ listen_port)

let subcommand_listen f =
  let doc = "Start chat application in listen mode and wait for connections" in
  Cmd.v (Cmd.info ~doc "listen") Term.(const f $ const ())

let chat client server =
  let doc = "A simple one to one terminal chatting application" in
  Cmd.(
    group (info "chat" ~doc)
      [ subcommand_connect client; subcommand_listen server ])

let cli_wrapper ~connect ~listen = Cmd.eval (chat connect listen) |> exit
