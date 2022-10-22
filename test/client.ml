open Lib.Sock_util

let client () =
  let sockaddr = Unix.ADDR_INET (Unix.inet_addr_loopback, 9000) in
  let _ic, oc = Unix.open_connection sockaddr in
  while true do
    Out_channel.output_string oc "HELLO";
    Unix.sleep 1
  done

let () = client ()
