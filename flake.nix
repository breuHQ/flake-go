{
  description = "breu.io go flake overlay for development";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        # Import nixpkgs for the current system. This provides access to packages.
        pkgs = import nixpkgs {inherit system;};
        # Get the go module builder. This is used to build go packages.
        buildGoModule = pkgs.buildGo123Module;

        # Base packages required for building and running go projects.
        _base = [
          pkgs.go_1_23
        ];

        # Development tools and packages. These extend the base for development.
        _dev = [
          pkgs.protobuf
          (pkgs.callPackage ./pkgs/air.nix {inherit buildGoModule;})
          (pkgs.callPackage ./pkgs/buf.nix {inherit buildGoModule;})
          (pkgs.callPackage ./pkgs/go-task.nix {inherit buildGoModule;})
          (pkgs.callPackage ./pkgs/golangci-lint.nix {inherit buildGoModule;})
        ];

        # Helper functions to manage packages and create development shells.
        setup = {
          # `setup.base` takes a list of packages `extend` and adds them to the beginning of the base package list.
          # For example: `setup.base [pkgs.delve]` returns `[pkgs.delve pkgs.go_1_23]`.
          base = extend:
            extend ++ _base;

          # `setup.shell` creates a development shell environment.
          #
          # It takes a list of base packages, a list of additional packages `extend`, and an attribute set `env`
          # for environment variables. The resulting shell includes all specified packages and environment variables.
          # For example: `setup.shell base [pkgs.gotools] { MY_VAR = "test"; }` would create a shell with
          # go, protobuf, golangci-lint, buf, and gotools installed, and `MY_VAR` set to "test".
          shell = base: extend: env:
            pkgs.mkShell {
              nativeBuildInputs = [pkgs.pkgconf]; # Required for building some go packages.
              buildInputs = base;
              packages = extend ++ _dev;

              shellHook = ''
                echo "Development environment loaded."
                export GOROOT="${pkgs.go_1_23}/share/go"  # Set GOROOT to the correct path
              '';

              inherit env;
            };
        };

        # A basic development shell with only base packages and no extra environment variables
        seed = setup.shell _base [] {};
      in {
        setup = setup;

        overlay = final: prev: {
          setup = setup;
          prev = prev;
        };

        devShells.default = seed;
      }
    );
}
