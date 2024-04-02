{ pkgs, ... }:

{
  nix.settings.extra-experimental-features = [ "nix-command" "flakes" ];

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
    pulseaudio

    # Languages
    (python3.withPackages (ps: [ ps.ocflib ]))
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
    ocf.utils
    rsync
    tmux
    screen
    wget
    curl
    zip
    unzip
    git
    cups
  ];

  services = {
    openssh = {
      enable = true;
      settings.X11Forwarding = true;
    };

    envfs = {
      enable = true;
      extraFallbackPathCommands = ''
        ln -s ${pkgs.bash}/bin/bash $out/bash
        ln -s ${pkgs.zsh}/bin/zsh $out/zsh
        ln -s ${pkgs.fish}/bin/fish $out/fish
        ln -s ${pkgs.xonsh}/bin/xonsh $out/xonsh
      '';
    };

    pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
      alsa.enable = true;
    };

    fwupd.enable = true;
    avahi.enable = true;
  };

  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;

  programs = {
    zsh.enable = true;
    fish.enable = true;
    xonsh.enable = true;
    nix-ld.enable = true;
  };

  networking.firewall.enable = false;

  environment.etc = {
    papersize.text = "letter";
    "cups/lpoptions".text = "Default double";
    "cups/client.conf".text = ''
      ServerName printhost.ocf.berkeley.edu
      Encryption Always
    '';
  };

  # Instead of populating /etc/ocf using `environment.etc`, we use a systemd
  # service to pull the repository every 15 minutes. This allows us to keep
  # the repository up to date without needing to update the NixOS config.
  systemd = {
    services.sync-etc = {
      description = "Update OCF etc repository";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.ocf-sync-etc}/bin/sync-etc /etc/ocf";
      };
    };

    timers.sync-etc = {
      description = "Update OCF etc repository";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/15";
        RandomizedDelaySec = "15m";
        FixedRandomDelay = true;
      };
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
