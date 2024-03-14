{
  description = "NixOS desktop configuration for the Open Computing Facility";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    wayout.url = "github:ocf/wayout";
  };

  outputs = { self, nixpkgs, flake-utils, wayout }:
    let
      # ================
      # nixpkgs overlays
      # ================

      pkgs-x86_64-linux = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          (final: prev: {
            ocf.wayout = wayout.packages.x86_64-linux.default;
            ocf.plasma-applet-commandoutput = prev.callPackage ./pkgs/plasma-applet-commandoutput.nix { };
            ocf.catppuccin-sddm = prev.qt6Packages.callPackage ./pkgs/catppuccin-sddm.nix { };
          })
        ];
      };

      # ========================
      # NixOS Host Configuration
      # ========================

      # Put modules common to all hosts here.
      commonModules = [
        ./modules/ocf/auth.nix
        ./modules/ocf/de.nix
        ./modules/ocf/network.nix
        ./profiles/base.nix
      ];

      # Put modules for specific hosts here.
      hosts = {
        snowball = [ ./hosts/snowball.nix ];
        tornado = [ ./hosts/tornado.nix ];
      };

      # =====================
      # Colmena Configuration
      # =====================

      colmena = builtins.mapAttrs
        (host: modules: {
          imports = commonModules ++ modules;
          deployment.buildOnTarget = true;
          deployment.targetUser = "root";
        })
        hosts;

      colmenaOutputs = {
        colmena = colmena // {
          meta = { nixpkgs = pkgs-x86_64-linux; };
        };
      };

      # =======================
      # Dev Shell Configuration
      # =======================

      devShellOutputs = flake-utils.lib.eachDefaultSystem
        (system:
          let pkgs = import nixpkgs { inherit system; }; in {
            devShells.default = pkgs.mkShell {
              packages = [ pkgs.colmena ];
            };
          }
        );
    in
    colmenaOutputs // devShellOutputs;
}
