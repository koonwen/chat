open Cmdliner
open Core_unix

let subcommand_connect f =
  (* Inet CLI converter *)
  let inet_conv =
    let parse str =
      try Ok (Inet_addr.of_string str) with Failure e -> Error e
    in
    let print fmt ppf = Format.fprintf fmt "%s" @@ Inet_addr.to_string ppf in
    Arg.conv' (parse, print)
  in

  let host =
    let doc = "Host to connect to" in
    Arg.(
      value & pos 1 inet_conv Inet_addr.localhost & info [] ~docv:"HOST" ~doc)
  in

  let port =
    let doc = "Port number" in
    Arg.(value & pos 2 int 9000 & info [] ~docv:"PORT" ~doc)
  in

  let doc = "Attempt to connect to HOST to initiate chat" in
  Cmd.v (Cmd.info ~doc "connect") Term.(const f $ host $ port)

let subcommand_listen f =
  let doc = "Start chat application in listen mode and wait for connections" in
  Cmd.v (Cmd.info ~doc "listen") Term.(const f $ const ())

let chat client server =
  let doc = "A simple one to one terminal chatting application" in
  Cmd.(
    group (info "chat" ~doc)
      [ subcommand_connect client; subcommand_listen server ])

let cli_wrapper ~client ~server = Cmd.eval (chat client server) |> exit
