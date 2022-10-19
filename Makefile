.PHONY=switch
switch:
	opam switch create . 4.14.0 --deps-only

build:
	dune build -w --terminal-persistence=clear-on-rebuild

chat_h:
	dune exec -- chat --help

server:
	dune exec -- chat listen

client:
	dune exec -- chat connect
