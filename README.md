# Ledger

A ledger application built with OCaml using Dune, Dream web framework, and SQLite.

## Prerequisites

You can build and run this project using either Nix (recommended) or native OCaml tools.

### Option 1: Using Nix (Recommended)

Install [Nix](https://nixos.org/download.html) with flakes enabled.

### Option 2: Native OCaml

Install the following dependencies:
- OCaml (>= 5.0.0)
- Dune (>= 3.0)
- sqlite3 (>= 5.3.1)
- yojson (>= 2.2.2)
- dream (>= 1.0.0)
- lwt (>= 5.9.2)
- lwt_ppx (>= 5.9.2)

## Building

### With Nix

```bash
nix develop

dune build

# Or build release version
dune build --release
```

### Without Nix

```bash
opam install --deps-only .

dune build

# Or build release version
dune build --release
```

## Running

### Start the server

```bash
dune exec ledger_tool 

# Or if built with release flag
./_build/default/bin/server.exe
```

### Running tests

```bash
dune runtest
```

## Development

The project structure:
- `bin/` - Server executable
- `lib/` - Core library modules
- `test/` - Test suite
- `sample_requests.md` - Example API requests

For development with Nix, use `nix develop` to enter a shell with all dependencies and development tools (including OCaml LSP) available.
