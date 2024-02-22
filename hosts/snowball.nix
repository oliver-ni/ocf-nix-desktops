{ config, pkgs, ... }:

{
  imports = [
    ../hardware/ridge-test-pc.nix
  ];

  networking.hostName = "snowball";

  systemd.network.networks."10-wired" = {
    matchConfig.Name = "enp8s0";
    address = [
      "169.229.226.99/24"
      "2607:f140:8801::1:99/64"
    ];
    routes = [
      { routeConfig.Gateway = "169.229.226.1"; }
      { routeConfig.Gateway = "2607:f140:8801::1"; }
    ];
    linkConfig.RequiredForOnline = "routable";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
