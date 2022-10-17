open Lib

let () = Cli.cli_wrapper ~connect:Client.start_chat ~listen:Server.serve