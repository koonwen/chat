# chat
CLI Chat Application in OCaml

# TODO
- [x] CLI Parsing
- [ ] Add Lwt_logs to print out info
- [ ] Safe termination
- [ ] Testing
- [ ] Setup dependencies and build instructions


# Structure
```
.
├── Makefile
├── README.md
├── bin
│   ├── cli.ml
│   ├── dune
│   └── main.ml
├── chat.opam
├── dune-project
├── lib
│   ├── client.ml
│   ├── dune
│   ├── handler.ml
│   ├── serializer.ml
│   ├── server.ml
│   └── sockUtil.ml
└── test
    ├── chat.ml
    └── dune
```
