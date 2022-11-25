{
  description = "NixOS Configuration for the Open Computing Facility <https://ocf.berkeley.edu>";

  inputs = {
    # Pinned to NixOS 22.11 beta since that's coming out soon anyway.
    nixpkgs.url = github:nixos/nixpkgs/22.11-beta;

    # This seems to be the defacto set of utilities people use for a nice
    # experience configuring NixOS systems with flakes.
    utils.url = github:gytis-ivaskevicius/flake-utils-plus/v1.3.1;
  };

  outputs = { self, utils, ... }@inputs:
    utils.lib.mkFlake {
      inherit self inputs;

      supportedSystems = [ "aarch64-linux" "x86_64-linux" ];
      channelsConfig.allowUnfree = true;

      # NixOS will compare the currently set hostname to hosts.* and apply
      # the one that matches.
      # roles.kubernetes roles.kubernetesControlPlane roles.kubernetesWorker
      hosts.adenine.modules = [ ./hosts/adenine.nix ];
      hosts.guanine.modules = ./hosts/guanine.nix;
      hosts.cytosine.modules = ./hosts/cytosine.nix;
      hosts.thymine.modules = ./hosts/thymine.nix;
    };
}

