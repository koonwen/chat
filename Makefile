build:
	dune build -w --terminal-persistence=clear-on-rebuild

server:
	dune exec -- bin/server.exe

client:
	dune exec -- bin/client.exe