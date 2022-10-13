open Chat
open Lwt
open Lwt.Syntax
open Websocket_lwt_unix

(* Terminology *)
(* Machine A : Client *)
(* Machine B : Server *)
let _ = Lwt_log.(add_rule "wschat*" Info)
let section = Lwt_log.Section.make "wschat"

let extra_headers uri =
  Cohttp.Header.init_with "client_accept_uri" (Uri.to_string uri)

(* let server_handler (conn : Connected_client.t) = let endpt =
   Connected_client.http_request conn |> Cohttp. let* _ = Lwt_log.info_f
   ~section "Connection established with %s" (host_uri |> Uri.to_string) in
   Server.message_handler *)

let connect ~server_uri ~host_uri =
  (* Run a server on Machine A to accept a connection from Machine B *)
  let* server = Util.resolve_server_uri ~uri:server_uri in
  let* _ =
    Lwt_log.info_f ~section "Listening on %s" (server_uri |> Uri.to_string)
  in
  let _ =
    Lwt.catch
      (fun () -> establish_standard_server ~mode:server Server.message_handler)
      (function
        | exn ->
            Lwt_log.error ~exn ~section "Could not establish server" >>= exit 1)
  in

  (* Try to connect to a Machine B and provide the uri to this Machine A's
     server *)
  let* client = Util.resolve_client_uri ~uri:host_uri in
  let extra_headers = extra_headers server_uri in
  let* conn = Websocket_lwt_unix.connect ~extra_headers client server_uri in
  let* _ =
    Lwt_log.info_f ~section "Connection established with %s"
      (host_uri |> Uri.to_string)
  in
  Client.(send_message conn () <?> recv_ack conn ())

let () =
  let server_uri = "http://127.0.0.1:8001" |> Uri.of_string in
  let host_uri = "http://127.0.0.1:8000" |> Uri.of_string in
  Lwt_main.run (connect ~server_uri ~host_uri)
