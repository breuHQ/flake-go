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
        # Import nixpkgs for the current system.
        pkgs = import nixpkgs {inherit system;};
        # Get the go module builder.
        buildGoModule = pkgs.buildGo123Module;

        # Base packages required for building and running go projects.
        base = [
          pkgs.go_1_23
        ];

        # Extra packages for development.
        dev = [
          pkgs.protobuf
          (pkgs.callPackage ./pkgs/air.nix {inherit buildGoModule;})
          (pkgs.callPackage ./pkgs/buf.nix {inherit buildGoModule;})
          (pkgs.callPackage ./pkgs/go-task.nix {inherit buildGoModule;})
          (pkgs.callPackage ./pkgs/golangci-lint.nix {inherit buildGoModule;})
        ];

        # Helper functions to extend base and dev packages.
        setup = {
          # `setup.base` takes a list of packages `ext` and prepends them to the base packages.
          # For example: `setup.base [pkgs.delve]` would return `[pkgs.delve pkgs.go_1_23]`.
          base = ext:
            ext ++ base;

          # `setup.shell` takes a list of base packages, a list of extra packages `ext`, and an attrset `env` of environment variables.
          # It creates a development shell environment with all provided packages and environment variables.
          # For example: `setup.shell base [pkgs.gotools] { MY_VAR = "test"; }`
          # would return a development shell with go, delve, protobuf, golangci-lint, buf, and gotools installed and `MY_VAR` set to `"test"`.
          shell = base: ext: env:
            pkgs.mkShell {
              nativeBuildInputs = [pkgs.pkgconf]; # required for building some go packages.
              buildInputs = base;
              packages = dev ++ ext;

              shellHook = ''
                echo "Development environment loaded."
                export GOROOT="${pkgs.go_1_23}/share/go"  # Correctly set GOROOT
              '';

              inherit env;
            };
        };

        # Seed shell environment with base packages and no extra packages or environment variables.
        seed = setup.shell base [] {};
      in {
        overlay = final: prev: {
          setup = setup;
          prev = prev;
        };

        devShells.default = seed;
      }
    );
}
