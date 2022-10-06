type t = Lwt_io.input_channel -> Lwt_io.output_channel -> unit -> unit Lwt.t

let rtt_middleware _io _oc _next = failwith ""
