type t = Lwt_io.input_channel -> Lwt_io.output_channel -> unit -> unit Lwt.t

let rtt_middleware io oc next =
