open Unix
open Lwt
open Lwt.Syntax
open Core

let msg_table = Array.init 10 ~f:(fun _ -> Time_ns.now ())
let index = ref 0

let get_sockaddr host port =
  let sockaddr = ADDR_INET (host, port) in
  sockaddr

let rec handle_connection ic oc () =
  let* msg = Lwt_io.read_line_opt Lwt_io.stdin in
  match msg with
  | Some m ->
      msg_table.(!index) <- Time_ns.now ();
      let p_msg = Printf.sprintf "%d %s" !index m in
      Lwt_io.write_line oc p_msg >>= handle_response ic oc
  | None ->
      let _ = Lwt_io.close ic in
      let _ = Lwt_io.close oc in
      return_unit

and handle_response ic oc () =
  let* response = Lwt_io.read_line_opt ic in
  match response with
  | Some m ->
      let id = Scanf.sscanf m "%d" (fun num -> num) in
      let rtt =
        Time_ns.abs_diff (Time_ns.now ()) msg_table.(id)
        |> Time_ns.Span.to_string_hum
      in
      let recv = Printf.sprintf "[%s] Message Recieved" rtt in
      print_endline recv |> return >>= handle_connection ic oc
  | None -> failwith "Unhandled"

let connect_to_host host port =
  let open Lwt_unix in
  let socket_fd = socket PF_INET SOCK_STREAM 0 in
  let sockaddr = get_sockaddr host port in
  let* _ = Lwt_unix.connect socket_fd sockaddr in
  let ic, oc =
    Lwt_io.(of_fd ~mode:Input socket_fd, of_fd ~mode:Output socket_fd)
  in
  handle_connection ic oc () >>= fun _ -> Lwt_unix.close socket_fd

let client host port = Lwt_main.run (connect_to_host host port)
