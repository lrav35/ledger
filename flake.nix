{
  description = "Ledger";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ocamlPackages = pkgs.ocaml-ng.ocamlPackages_5_1;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "ledger";
          src = ./.;

          buildInputs = with ocamlPackages; [
            ocaml
            dune_3
            findlib
            sqlite3
            lwt
            ocaml-sqlite3
          ] ++ [ pkgs.sqlite ];

          buildPhase = ''
            dune build --release
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp _build/default/src/my-api.exe $out/bin/my-api
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with ocamlPackages; [
            ocaml
            dune_3
            findlib
            sqlite3
            lwt
            ocaml-sqlite3
            ocaml-lsp-server
          ] ++ [ pkgs.sqlite ];
        };
      });
}
