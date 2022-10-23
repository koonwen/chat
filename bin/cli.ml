open Cmdliner

let subcommand_connect f =
  (* Server Parameter *)
  let host =
    let doc = "HOST to connect to" in
    Arg.(
      value & pos 0 string "127.0.0.1"
      & info [] ~docv:"HOSTNAME | IPV4_ADDR" ~doc)
  in

  let host_port =
    let doc = "HOST port number" in
    Arg.(value & pos 1 string "9000" & info [] ~docv:"HOST_PORT" ~doc)
  in

  let doc = "Attempt to connect to HOST:HOST_PORT to initiate chat." in
  Cmd.v (Cmd.info ~doc "connect") Term.(const f $ host $ host_port)

let subcommand_listen f =
  let port =
    let doc = "HOST port number" in
    Arg.(value & pos 0 string "9000" & info [] ~docv:"HOST_PORT" ~doc)
  in

  let doc = "Start chat application in listen mode and wait for connections" in
  Cmd.v (Cmd.info ~doc "listen") Term.(const f $ port)

let chat client server =
  let doc = "A simple one to one terminal chatting application" in
  Cmd.(
    group (info "chat" ~doc)
      [ subcommand_connect client; subcommand_listen server ])

let cli_wrapper ~client ~server = Cmd.eval (chat client server) |> exit
