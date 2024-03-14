{ config, pkgs, ... }:

{
  nix.settings.extra-experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
    };

    efi.canTouchEfiVariables = true;
  };

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Temporary, make dedicated deploy user later
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlViRB5HH1bTaS1S7TcqVBSuxKdrbdhL2CmhDqc/t6A" # oliverni
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiiq/rSfG+bKmqKZfCSl1z2r7rc3Wt/Paya/JYmjdSO" # njha
  ];

  environment.enableAllTerminfo = true;
  environment.systemPackages = with pkgs; [
    # Shells
    bash
    zsh
    fish
    xonsh

    # System utilities
    dnsutils
    cpufrequtils

    # Languages
    python3
    poetry
    ruby
    elixir
    clojure
    ghc
    rustup
    clang

    # Editors
    vim
    emacs
    neovim
    helix
    kakoune

    # Other tools
    rsync
    tmux
    screen
    wget
    curl
    zip
    unzip
    git
  ];

  services = {
    openssh = {
      enable = true;
      settings.X11Forwarding = true;
    };

    fwupd.enable = true;
    envfs = {
      enable = true;
      extraFallbackPathCommands = ''
        ln -s ${pkgs.bash}/bin/bash $out/bash
        ln -s ${pkgs.zsh}/bin/zsh $out/zsh
        ln -s ${pkgs.fish}/bin/fish $out/fish
        ln -s ${pkgs.xonsh}/bin/xonsh $out/xonsh
      '';
    };
  };

  programs = {
    zsh.enable = true;
    fish.enable = true;
    xonsh.enable = true;
    nix-ld.enable = true;
  };

  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
