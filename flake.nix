{
  description = "NixOS desktop configuration for the Open Computing Facility";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils-plus.url = github:gytis-ivaskevicius/flake-utils-plus/v1.4.0;
  };

  outputs = inputs@{ self, nixpkgs, flake-utils-plus }: flake-utils-plus.lib.mkFlake {
    inherit self inputs;
    supportedSystems = [ "x86_64-linux" ];
    hostDefaults.modules = [ ./profiles/base.nix ];

    # Desktops
    hosts.snowball.modules = [ ./hosts/snowball.nix ./profiles/desktop.nix ];
  };
}
