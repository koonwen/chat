open Unix
open Lwt
open Lwt.Syntax
open Core

module Config = struct
  let msg_table = Array.init 1 ~f:(fun _ -> Time_ns.now ())
  let index = ref 0

  (* Only IPv4 supported *)
  let create_sockaddr host port =
    let sockaddr = ADDR_INET (host, port) in
    sockaddr

  (* Abstract the incrementing logic here *)
end

let handle_connection socket_fd =
  let ic, oc =
    Lwt_io.(of_fd ~mode:Input socket_fd, of_fd ~mode:Output socket_fd)
  in

  let rec send_message () =
    let* msg = Lwt_io.read_line_opt Lwt_io.stdin in
    match msg with
    | Some m ->
        Config.msg_table.(!Config.index) <- Time_ns.now ();
        let p_msg = Printf.sprintf "%d %s" !Config.index m in
        Lwt_io.write_line oc p_msg >>= handle_response
    | None ->
        let _ = Lwt_io.close ic in
        let _ = Lwt_io.close oc in
        return_unit
  and handle_response () =
    let* response = Lwt_io.read_line_opt ic in
    match response with
    | Some m ->
        let id = Scanf.sscanf m "%d" (fun num -> num) in
        if id = -1 then Lwt_io.printl m
        else
          let rtt =
            Time_ns.abs_diff (Time_ns.now ()) Config.msg_table.(id)
            |> Time_ns.Span.to_string_hum
          in
          let recv = Printf.sprintf "[%s] Message Recieved" rtt in
          print_endline recv |> return >>= send_message
    | None -> failwith "Unhandled"
  in

  send_message ()

let connect_to_host host port =
  let open Lwt_unix in
  let socket_fd = socket PF_INET SOCK_STREAM 0 in
  let sockaddr = Config.create_sockaddr host port in
  let* _ = Lwt_unix.connect socket_fd sockaddr in
  return socket_fd

let connect host port =
  let* socket_fd = connect_to_host host port in
  let* _ = handle_connection socket_fd in
  Lwt_unix.close socket_fd
