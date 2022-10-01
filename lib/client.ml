open! Lwt.Infix
open! Lwt.Syntax
open Websocket_lwt_unix

let section = Lwt_log.Section.make "wscat"

let client uri =
  let open Websocket in
  Resolver_lwt.resolve_uri ~uri Resolver_lwt_unix.system >>= fun endp ->
  let ctx = Lazy.force Conduit_lwt_unix.default_ctx in
  Conduit_lwt_unix.endp_to_client ~ctx endp >>= fun client ->
  connect ~ctx client uri >>= fun conn ->
  let close_sent = ref false in
  let rec react () =
    Websocket_lwt_unix.read conn >>= function
    | { Frame.opcode = Ping; _ } ->
        write conn (Frame.create ~opcode:Pong ()) >>= react
    | { opcode = Close; content; _ } ->
        (* Immediately echo and pass this last message to the user *)
        (if !close_sent then Lwt.return_unit
        else if String.length content >= 2 then
          write conn
            (Frame.create ~opcode:Close ~content:(String.sub content 0 2) ())
        else write conn (Frame.close 1000))
        >>= fun () -> Websocket_lwt_unix.close_transport conn
    | { opcode = Pong; _ } -> react ()
    | { opcode = Text; content; _ } | { opcode = Binary; content; _ } ->
        Lwt_io.printf "> %s\n> %!" content >>= react
    | _ -> Websocket_lwt_unix.close_transport conn
  in
  let rec pushf () =
    Lwt_io.(read_line_opt stdin) >>= function
    | None ->
        Lwt_log.debug ~section "Got EOF. Sending a close frame." >>= fun () ->
        write conn (Frame.create ~opcode:Close ()) >>= fun () ->
        close_sent := true;
        pushf ()
    | Some content -> write conn (Frame.create ~content ()) >>= pushf
  in
  pushf () <?> react ()