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

## Extending the Environment

Let's examine how to include it in a project with a `cmd/quantm` Go binary that also needs `libgit2`:

```nix
{
  description = "Project using the breu.io go flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05"; # Keep this consistent with the breu.io flake
    breu-go.url = "github:breuhq/flake-go";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, breu-go, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
        let
          pkgs = import nixpkgs { inherit system; };

          # Add libgit2 to the base environment
          base = breu-go.overlay.setup.base [
            pkgs.libgit2
          ];

          # Set up the development shell with our base packages
          shell = breu-go.overlay.setup.shell base [];

          # Define how to build the quantm binary
          quantm = pkgs.stdenv.mkDerivation {
              name = "quantm";
              src = ./.;
              buildInputs = base;

              buildPhase = ''
                go build -tags static -o $out/bin/quantm ./cmd/quantm
              '';

              installPhase = ''
                mkdir -p $out/bin
                cp $out/bin/quantm $out/bin
              '';
          };
        in
          {
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
```
