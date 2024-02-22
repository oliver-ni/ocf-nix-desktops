{
  description = "NixOS desktop configuration for the Open Computing Facility";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils }:
    let
      # Put modules common to all hosts here.
      commonModules = [ ./profiles/base.nix ];

      # Put modules for specific hosts here.
      hosts = {
        snowball = [ ./hosts/snowball.nix ./profiles/auth.nix ./profiles/desktop.nix ];
      };

      # Build comena config
      colmena = builtins.mapAttrs
        (host: modules: {
          imports = commonModules ++ modules;
          deployment.buildOnTarget = true;
          deployment.targetUser = "root";
        })
        hosts;

      # Build dev shell config
      devShells = flake-utils.eachDefaultSystem
        (system:
          let pkgs = import nixpkgs { inherit system; };
          in {
            default = pkgs.mkShell {
              packages = [ pkgs.colmena ];
            };
          }
        );
    in
    {
      inherit devShells;

      colmena = colmena // {
        meta = {
          # This can be overriden by the system-specific configuration
          nixpkgs = import nixpkgs { system = "x86_64-linux"; };
        };
      };
    };
}
