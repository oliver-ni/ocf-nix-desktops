{
  description = "NixOS desktop configuration for the Open Computing Facility";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils-plus.url = github:gytis-ivaskevicius/flake-utils-plus/v1.4.0;
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils-plus, deploy-rs }: flake-utils-plus.lib.mkFlake {
    inherit self inputs;

    supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    sharedOverlays = [ deploy-rs.overlay ];
    hostDefaults.modules = [ ./profiles/base.nix ];

    # Desktops
    hosts.snowball.modules = [ ./hosts/snowball.nix ./profiles/desktop.nix ];

    outputsBuilder = channels: {
      devShells.default = channels.nixpkgs.mkShell {
        packages = [ channels.nixpkgs.deploy-rs.deploy-rs ];
      };
    };

    deploy.nodes.snowball = {
      hostname = "snowball";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.snowball;
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
