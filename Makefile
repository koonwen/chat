build:
	dune build -w --terminal-persistence=clear-on-rebuild

chat_h:
	dune exec -- chat --help

server:
	dune exec -- chat listen

client:
	dune exec -- chat connect
