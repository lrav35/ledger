(lang dune 3.19)
(name ledger_tool)
(generate_opam_files true)

(package
 (name ledger_tool)
 (depends
  (ocaml (>= 5.0.0))
  (dune (>= 3.0))
  (sqlite3 (>= 5.3.1))
  (yojson (>= 2.2.2))
  (dream (>= 1.0.0))
  (lwt (>= 5.9.2))
  (lwt_ppx (>= 5.9.2))
 )
)
