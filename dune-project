(lang dune 3.1)

(name chat)

(generate_opam_files true)

(source
 (github koonwen/chat))

(authors "Lee Koonwen")

(maintainers "Lee Koonwen")

(package
 (name chat)
 (synopsis "A CLI Chat application in OCaml")
 (description
  "Chat application that can be started in two modes: client/server.Both sides can send and recieve messages, the sending side shows the RTT time for the message to be delivered. After connection is terminated by the client, the server can continue accepting connections")
 (depends
  (ocaml
   (>= 4.14.0))
  dune
  core_unix
  lwt
  logs
  cmdliner
  ocaml-lsp-server:dev
  ocamlformat:dev)
 (tags
  (chat client server tcp_lwt cohttp_lwt websocket_lwt)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
