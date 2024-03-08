{
  description = "NixOS desktop configuration for the Open Computing Facility";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
    wayout.url = "github:ocf/wayout";
  };

  outputs = { self, nixpkgs, flake-utils, wayout }:
    let
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
          meta = {
            # This can be overriden by the system-specific configuration
            nixpkgs = import nixpkgs {
              system = "x86_64-linux";
              overlays = [ (final: prev: { ocf.wayout = wayout.packages.x86_64-linux.default; }) ];
            };
          };
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
