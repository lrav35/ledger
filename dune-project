(lang dune 3.19)
(name ledger_tool)
(generate_opam_files true)

(package
 (name ledger_tool)
 (depends
  (ocaml (>= 5.0.0))
  (dune (>= 3.0))
  (csv (>= 2.4))
  (sqlite3 (>= 5.3.1))
  (cmdliner (>= 1.3))
 )
)
