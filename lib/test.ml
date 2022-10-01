open Websocket_lwt_unix
open Lwt.Syntax
open Lwt

module Middleware = struct
  type t =
    (Connected_client.t -> unit Lwt.t) -> Connected_client.t -> unit Lwt.t

  let open_connection_limit = 1
  let live_connections = ref 0

  let validate_conn (next : Connected_client.t -> unit Lwt.t) client =
    incr live_connections;
    if !live_connections > open_connection_limit then
      failwith "Exceeded Connections"
    else next client >|= fun _ -> decr live_connections

  let install (middleware_list : t list) main_handler client =
    List.fold_left (fun h m -> m h) main_handler middleware_list @@ client
end

let response = Websocket.Frame.create ~content:"Message Recieved!" ()

let rec main_handler client =
  let open Connected_client in
  let* in_frame = recv client in
  match in_frame with
  | { opcode = Text; content; _ } ->
      let _ = Lwt_io.printl content in
      send client response >>= (* Reuse the main_handler *)
                           fun _ -> main_handler client
  | { opcode = Close; _ } -> Lwt_io.printl "Connection Terminated"
  | _ -> failwith "Not implemented"

let () =
  let mode = `TCP (`Port 8000) in
  let server = Middleware.(install [ validate_conn ] main_handler) in
  Lwt_main.run (establish_standard_server ~mode server)
