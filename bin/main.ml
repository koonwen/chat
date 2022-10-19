open Lib

let () = Cli.cli_wrapper ~client:Client.start_chat ~server:Server.serve