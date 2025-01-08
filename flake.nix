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
        pkgs = import nixpkgs {inherit system;};
        buildGoModule = pkgs.buildGo123Module;

        # base packages required for building and running go projects.
        base = [
          pkgs.go_1_23.env
        ];

        # extra packages for development.
        dev = [
          pkgs.protobuf
          (pkgs.callPackage ./pkgs/golangci-lint.nix {inherit buildGoModule;})
          (pkgs.callPackage ./pkgs/buf.nix {inherit buildGoModule;})
        ];

        # helper functions to extend base and dev packages.
        setup = {
          # setup base packages.
          base = extended:
            extended ++ base;
          # setup shell environment.
          shell = base: extended:
            pkgs.mkShell {
              packages = base ++ dev ++ extended;
              shellHook = ''
                echo "Development environment loaded."
              '';
            };
        };

        # seed shell environment.
        seed = setup.shell base [];
      in {
        overlay = final: prev: {
          setup = setup;
          prev = prev;
        };

        devShells.default = seed;
      }
    );
}
