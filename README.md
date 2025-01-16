# breu.io Go Flake

> [!NOTE]
> This is a work in progress. The surface area of the flake is still being defined and may change.

Designed as an overlay for import into other Go projects, it provides helper functions for easy customization of both base and shell environments.

## Features

*   **Base Go Environment**: Includes a pre-configured Go toolchain (currently using Go 1.23).
*   **Development Tools**: Includes protobuf tools, golangci-lint, and buf for code quality and protobuf handling.
*   **Customizable**: Easily extendable with more packages and tools.
*   **Shell Environment**: Provides a consistent shell environment for Go development with helper functions to allow customization.
*   **Overlay Based**: Can be imported into other Nix flakes.
*   **Simplified `setup`**: Now `setup.base` and `setup.shell` are accessed directly through the `overlay` attribute, making usage cleaner.

## Extending the Environment

Let's examine how to include it in a project with a `cmd/quantm` Go binary that also needs `libgit2`:

```nix
{
  description = "project using breuhq/flake-go";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";

    breu.url = "github:breuhq/flake-go";
  };

  outputs = {
    nixpkgs,
    breu,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
        buildGoModule = pkgs.buildGo123Module;

        # Apply the breu-go overlay to get access to go tooling
        pkgs_ = pkgs.extend (final: prev: breu.overlay.${system} final prev);

        # Base packages required for building and running quantm
        base = pkgs_.setup.base [
          pkgs.openssl
          pkgs.http-parser
          pkgs.zlib
          pkgs.python3 # required for http-parser in libgit2
          pkgs.libgit2
        ];

        # Development packages for use in the dev shell
        dev = [
          pkgs.libpg_query # FIXME: probably not required anymore.
          (pkgs.callPackage ./tools/nix/sqlc.nix {inherit buildGoModule;})
        ];

        # Set up the development shell with our base and dev packages
        shell = pkgs_.setup.shell base dev {};

        # Build the quantm binary
        quantm = pkgs.stdenv.mkDerivation {
          name = "quantm";
          src = ./.;

          nativeBuildInputs = base;

          buildPhase = ''
            export GOROOT="${pkgs.go_1_23}/share/go"
            go build -x -tags static,system_libgit2 -o $out/bin/quantm ./cmd/quantm
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp $out/bin/quantm $out/bin/quantm
          '';
        };
      in {
        devShells.default = shell;
        packages.quantm = quantm;
      }
    );
}
```

## How to Use It: The Basics

Here's how to use the development shell and build the `quantm` binary.

### Entering the Development Shell

To enter a development shell with the appropriate tools, navigate to the root of your project (where the `flake.nix` that imports `breu-go` is located) and run:

```bash
nix develop
```

The command will provide a shell with Go 1.23, protobuf tools, `golangci-lint`, `buf`, and any other packages included when extending the base.

### Building the Binary

To build the `quantm` binary as defined in the `flake.nix`, use:

```bash
nix build .#quantm
```

This will build the `quantm` binary and place it in the `result` directory. To execute the binary from that directory, use:

```bash
./result/bin/quantm
```

To install the binary into the system's `~/.nix-profile/bin` for easy access, use:

```bash
nix profile install .#quantm
```

This makes the `quantm` binary accessible directly from the terminal through your `$PATH`.
