.PHONY=switch
switch:
	opam switch create . 4.14.0 --deps-only
	eval $(opam env)

build:
	dune build -w --terminal-persistence=clear-on-rebuild

# Get manpage for CLI commands
chat_h:
	dune exec -- chat --help

# Start listening on 127.0.0.1:9000
server:
	dune exec -- chat listen

# Connect to 127.0.0.1:9000
client:
	dune exec -- chat connect
