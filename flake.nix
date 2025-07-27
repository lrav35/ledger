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
        ocamlPackages = pkgs.ocaml-ng.ocamlPackages_5_2;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "ledger";
          src = ./.;

          buildInputs = with ocamlPackages; [
            ocaml
            dune_3
            findlib
            lwt
            ocaml_sqlite3
            dream
            yojson
            lwt_ppx
          ] ++ [ pkgs.sqlite ];

          buildPhase = ''
            dune build --release
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp _build/default/bin/server.exe $out/bin/server
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with ocamlPackages; [
            ocaml
            dune_3
            findlib
            lwt
            ocaml_sqlite3
            ocaml-lsp
            alcotest
            dream
            yojson
            lwt_ppx
          ] ++ [ pkgs.sqlite ];
        };
      }) // {
        nixosModules.ledger = { config, pkgs, ... }: {
          imports = [ ./ledger-service.nix ];
          nixpkgs.overlays = [
            (final: prev: {
              ledger = self.packages.${final.system}.default;
            })
          ];
        };
      };
}
