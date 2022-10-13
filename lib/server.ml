open Websocket_lwt_unix
open Lwt.Syntax
open Lwt

module Middleware = struct
  type t =
    (Connected_client.t -> unit Lwt.t) -> Connected_client.t -> unit Lwt.t

  let install (middleware_list : t list) main_handler client =
    List.fold_left (fun h m -> m h) main_handler middleware_list @@ client

  let open_connection_limit = 1
  let live_connections = ref 0

  let validate_conn (next : Connected_client.t -> unit Lwt.t) client =
    incr live_connections;
    if !live_connections > open_connection_limit then
      failwith "Exceeded Connections"
    else
      let req = Connected_client.http_request client in
      assert (Websocket.check_origin_with_host req);
      next client >|= fun _ -> decr live_connections
end

let make_response =
  let counter = ref 0 in
  fun () ->
    incr counter;
    let content = Printf.sprintf "Message %d Recieved!" !counter in
    Websocket.Frame.create ~content ()

let rec message_handler client =
  let open Connected_client in
  let* in_frame = recv client in
  match in_frame with
  | { opcode = Text; content; _ } ->
      let fmt_msg = ">>> " ^ content in
      let _ = Lwt_io.printl fmt_msg in
      send client (make_response ()) >>= (* Reuse the message_handler *)
                                     fun _ -> message_handler client
  | { opcode = Close; _ } -> Lwt_io.printl "Connection Terminated"
  | _ -> failwith "Not implemented"

let get_server_uri conn_client =
  let headers =
    Connected_client.http_request conn_client |> Cohttp.Request.headers
  in
  match Cohttp.Header.get headers "client_accept_uri" with
  | Some uri -> uri |> Uri.of_string
  | None -> failwith "No client_uri"
