{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    outputs = flake-utils.lib.eachSystem systems (system: let
      pkgs = import nixpkgs {inherit system;};
      buildGoModule = pkgs.buildGo123Module;
    in rec {
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
              export GOROOT="${pkgs.go_1_23}/share/go"
            '';

            inherit env;
          };
      };

      # Seed shell environment with base packages and no extra packages or environment variables.
      seed = setup.shell base [] {};

      devShells.default = seed;
    });
  in
    outputs
    // {
      overlay = final: prev: {
        setup = outputs.setup;
        prev = prev;
      };
    };
}
