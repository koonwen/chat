open! Lib.Sock_util

let server () =
  let sockaddr = Unix.ADDR_INET (Unix.inet_addr_loopback, 9000) in
  let rec handler ic _oc =
    let s = In_channel.input_all ic in
    print_endline s;
    handler ic _oc
  in
  Unix.establish_server handler sockaddr
(* let fd = create_server_socket Unix.inet_addr_loopback 9000 in
   let sock, _ = Unix.accept fd in
   let buffer = Bytes.create 10 in
   Unix.sleep 2;
   while true do
     let _ = Unix.recv sock buffer 0 5 [] in
     Printf.printf "%s%!" (Bytes.to_string buffer);
     Unix.sleep 1
   done *)

let () = server ()
