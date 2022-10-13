open Lwt
open Lwt.Syntax
open Conduit_lwt_unix

let resolve_uri ~uri =
  let* endp = Resolver_lwt.resolve_uri ~uri Resolver_lwt_unix.system in
  let ctx = Lazy.force default_ctx in
  return (ctx, endp)

let resolve_server_uri ~uri =
  let* ctx, endp = resolve_uri ~uri in
  endp_to_server ~ctx endp

let resolve_client_uri ~uri =
  let* ctx, endp = resolve_uri ~uri in
  endp_to_client ~ctx endp
