(* Serializer/Deserializer for data sent over the connection. *)

(* Data format
   byte = 0x8

   id  | code | message
   0x8   0x8    0x8 .... \n
*)

type code = Ack | Msg

let decode code =
  match Char.code code with 0 -> Ack | 1 -> Msg | _ -> failwith "Invalid code"

let encode code =
  let i = match code with Ack -> 0 | Msg -> 1 in
  Char.chr i

type packet = { id : int; code : code; content : string }

(** args [?id ?content] can be ommitted when making packets for code *)
let make_packet ?(id = 255) ?(content = "\n") code = { id; code; content }

let deserialize str =
  let id, code, content =
    Scanf.sscanf str "%c%c%s@\n" (fun id code content ->
        (Char.code id, decode code, content))
  in
  { id; code; content }

let serialize { id; code; content } =
  Printf.sprintf "%c%c%s\n" (Char.chr id) (encode code) content

let send oc t =
  let s = serialize t in
  Lwt_io.write oc s