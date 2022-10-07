open Lwt
open Lwt.Syntax
open Core

module Config = struct
  let msg_table = Array.init 1 ~f:(fun _ -> Time_ns.now ())
  let index = ref 0

  (* Abstract the incrementing logic here *)
end

let message_handler ic oc =
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

let handle_connection socket_fd handler =
  let ic, oc =
    Lwt_io.(of_fd ~mode:Input socket_fd, of_fd ~mode:Output socket_fd)
  in
  handler ic oc

let connect host port =
  let socket = Util.new_socket () in
  let sockaddr = Util.get_sockaddr host port in
  Core_unix.connect socket ~addr:sockaddr;
  let socket_fd = Lwt_unix.of_unix_file_descr socket in
  let* _ = handle_connection socket_fd message_handler in
  Lwt_unix.close socket_fd
