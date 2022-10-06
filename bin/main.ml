let () =
  let open Lib in
  Cli.cli_wrapper ~client:Client.client ~server:Server.server
