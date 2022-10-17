(* Serializer/Deserializer for data sent over the connection. *)
open Lwt

type packet = { id : int; flag : bool; content : string }

let deserialize s =
  let id, flag, content =
    Scanf.sscanf s "%d%b%s@\n" (fun id flag content -> (id, flag, content))
  in
  { id; flag; content }

let serialize { id; flag; content } = Printf.sprintf "%d%b%s\n" id flag content

let on_recv ic =
  Lwt_io.read_line_opt ic >|= function
  | Some s -> deserialize s
  | None -> failwith "Nothing"

let to_send oc t =
  let s = serialize t in
  Lwt_io.write oc s