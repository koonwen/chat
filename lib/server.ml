open Core
open! Lwt
open! Lwt.Syntax

module Handler = struct
  type t = Lwt_io.input_channel -> Lwt_io.output_channel -> unit -> unit Lwt.t

  let aux_message_handler msg =
    match msg with
    | "exit" -> failwith "Close connection"
    | msg ->
        let id, msg =
          match String.lsplit2 msg ~on:' ' with
          | Some pair -> pair
          | None -> failwith ""
        in
        let fmt_msg = Printf.sprintf ">>> %s" msg in
        (id, fmt_msg)

  let rec message_handler ic oc () =
    Lwt_io.read_line_opt ic >>= fun msg ->
    match msg with
    | Some msg ->
        let id, msg = aux_message_handler msg in
        print_endline msg;
        Lwt_io.write_line oc id >>= message_handler ic oc
    | None -> Logs_lwt.info (fun m -> m "Connection closed") >>= return
end

let handle_connection socket_fd handler =
  let ic = Lwt_io.of_fd ~mode:Lwt_io.Input socket_fd in
  let oc = Lwt_io.of_fd ~mode:Lwt_io.Output socket_fd in
  handler ic oc ()
