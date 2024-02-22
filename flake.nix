{
  description = "NixOS desktop configuration for the Open Computing Facility";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils-plus.url = github:gytis-ivaskevicius/flake-utils-plus/v1.4.0;
  };

  outputs = inputs@{ self, nixpkgs, flake-utils-plus }: flake-utils-plus.lib.mkFlake {
    inherit self inputs;
    supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

    # =============
    # NixOS systems
    # =============

    hostDefaults.modules = [ ./profiles/base.nix ];
    hosts.snowball.modules = [ ./hosts/snowball.nix ./profiles/desktop.nix ];

    # ==============
    # colmena config
    # ==============

    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
      };

      snowball = { ... }: {
        imports = [ ./hosts/snowball.nix ./profiles/base.nix ./profiles/desktop.nix ];
        deployment.buildOnTarget = true;
        deployment.targetUser = "root";
      };
    };

    # ===============
    # Dev Shell setup
    # ===============

    outputsBuilder = channels: {
      devShells.default = channels.nixpkgs.mkShell {
        packages = [ channels.nixpkgs.colmena ];
      };
    };
  };
}
