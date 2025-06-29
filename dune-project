(lang dune 3.19)
(name bach_ledger_tool)
(generate_opam_files true)

(package
 (name bach_ledger_tool)
 (depends
  (ocaml (>= 5.0.0))
  (dune (>= 3.0))
  (csv (>= 2.4))
  (cmdliner (>= 1.3))
 )
)
