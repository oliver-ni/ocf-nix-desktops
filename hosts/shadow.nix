{ config, pkgs, ... }:

{
  imports = [
    ../hardware/shadow.nix
  ];

  networking.hostName = "shadow";

  fileSystems."/home" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=16G" "mode=755" ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.modesetting.enable = true;

  ocf = {
    auth.enable = true;
    graphical.enable = true;

    network = {
      enable = true;
      interface = "enp9s0";
      lastOctet = 143;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
