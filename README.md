# chat
CLI Chat Application in OCaml

# TODO
- [x] CLI Parsing
- [x] Setup dependencies and build instructions
- [ ] Add Lwt_logs to print out info
- [ ] Safe termination
- [ ] Testing

# Build & Running
```bash
# Install switch and dependencies
make switch
# To pull up the CLI interface
dune exec -- chat --help
# Run server
dune exec -- chat listen [PORT]
# Run client
dune exec -- chat server [HOST] [PORT]
```
To terminate connection from the client, use CTRL-D.

**Note** Safe termination using CTRL-C not yet implemented.
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

# Pipeline
![Pipeline UML diagram](resources/chat.png)