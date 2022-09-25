open Lwt
open Cohttp
open Cohttp_lwt_unix

let send_message host_uri msg =
  Client.post
    ~body:(Cohttp_lwt.Body.of_string msg)
    ~headers:(Header.init_with "time" "now")
    host_uri
  >>= (* On callback message *)
  fun (resp, body) ->
  let code = resp |> Response.status |> Code.code_of_status in
  (* Check that message was received successfully *)
  assert (code = 200);
  (* Print "message received" indication *)
  body |> Cohttp_lwt.Body.to_string >|= print_endline

let start_chat host_uri () =
  let rec loop () =
    let msg = read_line () in
    send_message host_uri msg >>= loop
  in
  loop ()

let connect ~host_uri =
  let uri = host_uri |> Uri.of_string in
  Client.head uri >>= fun resp ->
  resp |> Response.status |> function
  (* Upon successful connection, start chat *)
  | `No_content ->
      print_endline "Connection established";
      start_chat uri ()
  | _ -> print_endline "Connection failed" |> return
