open! Lwt
open! Cohttp
open Cohttp_lwt_unix

(* Initial connection callback *)
let create_client_connection _req =
  Server.respond ~status:`No_content ~body:Cohttp_lwt.Body.empty ()

(* Message reception callback *)
let rec recieve_message req body =
  assert (Request.is_keep_alive req);
  body |> Cohttp_lwt.Body.to_string >|= print_endline
  >>= Server.respond_string ~status:`OK ~body:"Message Recieved"

(* The server should only allow recieving messages if there is an initial
   connection made *)
let server =
  let callback _conn req body =
    req |> Request.meth |> function
    | `HEAD -> create_client_connection req
    | `POST -> recieve_message req body
    | _ -> failwith ""
  in
  Server.make ~callback ()

let listen () =
  Lwt_main.run (Server.create ~backlog:1 ~mode:(`TCP (`Port 8000)) server)
