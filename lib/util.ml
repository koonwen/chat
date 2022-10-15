open Lwt
open Lwt.Syntax
open Conduit_lwt_unix

let get_ip = function `TCP (ip, _) -> ip | _ -> failwith "Not implemented"

let host_to_uri ip =
  let uri = Uri.of_string ip in
  Format.printf "%a\n%!" Uri.pp uri;
  (match Uri.scheme uri with
  | Some v -> Printf.printf "scheme %s%!" v
  | _ -> ());
  uri

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
