# chat
CLI Chat Application in OCaml

# TODO
- [x] CLI Parsing
- [ ] Add Lwt_logs to print out info
- [ ] Safe termination
- [ ] Testing
- [ ] Setup dependencies and build instructions


# Structure
lib
- client: Start listener (validate client connecting) and THEN attempt to connect to the server
- server : Listen and upon connection THEN attempt to connect to the server