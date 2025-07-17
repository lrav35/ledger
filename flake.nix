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
            csv
            cmdliner
            yojson
            ppx_deriving_yojson
          ] ++ [ pkgs.sqlite ];

          buildPhase = ''
            dune build --release
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp _build/default/bin/main.exe $out/bin/main
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
            csv
            cmdliner
            yojson
            ppx_deriving_yojson
            alcotest
          ] ++ [ pkgs.sqlite ];
        };
      }) // {
        nixosModules.ledger = { config, pkgs, ... }: {
          imports = [ ./ledger-service.nix ];
          environment.systemPackages = [ self.packages.x86_64-linux.default ];
        };
      };
}
