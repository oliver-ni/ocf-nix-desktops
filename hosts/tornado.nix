{ config, pkgs, ... }:

{
  imports = [
    ../hardware/nuc.nix
  ];

  networking.hostName = "tornado";

  ocf = {
    auth.enable = true;

    network = {
      enable = true;
      interface = "enp89s0";
      lastOctet = 90;
    };
  };

  services.cage = {
    enable = true;
    program = "${pkgs.chromium}/bin/chromium --noerrdialogs --disable-infobars --kiosk https://labmap.ocf.berkeley.edu";
    user = "ocftv";
  };

  systemd.services."cage-tty1".after = [
    "network-online.target"
    "systemd-resolved.service"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
