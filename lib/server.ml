open Lwt.Infix
open Lwt.Syntax
open Websocket_lwt_unix

let section = Lwt_log.Section.make "wscat"

let rec react client client_id =
  let open Websocket in
  let* fr = Connected_client.recv client in
  let* _ = Lwt_log.debug_f ~section "Client %d: %S" client_id Frame.(show fr) in
  match fr.opcode with
  | Frame.Opcode.Ping ->
      let* _ =
        Connected_client.send client
          Frame.(create ~opcode:Opcode.Pong ~content:fr.content ())
      in
      react client client_id
  | Close ->
      (* Immediately echo and pass this last message to the user *)
      if String.length fr.content >= 2 then
        let content = String.sub fr.content 0 2 in
        Connected_client.send client
          Frame.(create ~opcode:Opcode.Close ~content ())
      else Connected_client.send client @@ Frame.close 1000
  | Pong -> react client client_id
  | Text | Binary ->
      let* _ = Connected_client.send client fr in
      react client client_id
  | _ -> Connected_client.send client Frame.(close 1002)

let server uri =
  let id = ref (-1) in
  let echo_fun client =
    incr id;
    let id = !id in
    Lwt_log.info_f ~section "Connection from client id %d" id >>= fun () ->
    Lwt.catch
      (fun () -> react client id)
      (fun exn ->
        Lwt_log.error_f ~section ~exn "Client %d error" id >>= fun () ->
        Lwt.fail exn)
  in
  let* endp = Resolver_lwt.resolve_uri ~uri Resolver_lwt_unix.system in
  let open Conduit_lwt_unix in
  let endp_str = endp |> Conduit.sexp_of_endp |> Sexplib.Sexp.to_string_hum in
  let* _ = Lwt_log.info_f ~section "endp = %s" endp_str in
  let ctx = Lazy.force default_ctx in
  let* server = endp_to_server ~ctx endp in
  let server_str = server |> sexp_of_server |> Sexplib.Sexp.to_string_hum in
  let* _ = Lwt_log.info_f ~section "server = %s" server_str in
  establish_server ~ctx ~mode:server echo_fun