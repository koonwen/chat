(lang dune 3.1)

(name chat)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Author Name")

(maintainers "Maintainer Name")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name chat)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends
  (ocaml
   (>= 4.14.0))
  dune
  cohttp-lwt-unix)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
