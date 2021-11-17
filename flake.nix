{
  description = "Reusable Nix utilities for Mars Research projects";

  inputs = {
    nixpkgs.url = "github:mars-research/nixpkgs/mars-21.11";

    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }: let
    supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

    lib = {
      inherit (flake-utils.lib) defaultSystems eachSystem;
    };
    platformOutputs = lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (import rust-overlay)
          (import ./pkgs)
        ];
      };
    in rec {
      legacyPackages = pkgs;

      devShell = pkgs.mkShell {
        buildInputs = [ pkgs.mars-research.mars-tools ];
      };

      reproduce = pkgs.mars-research.mkReproduceHook {
        requirements = {
          cloudlab = "c220g2";
        };
        script = ''
          echo This is a sample script that should print out human-readable results.
        '';
      };
    });
  in platformOutputs // rec {
    inherit lib;

    overlay = import ./pkgs;

    templates = import ./templates;
    defaultTemplate = templates.rust;
  };
}
