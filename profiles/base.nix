{ pkgs, lib, inputs, ... }:

{
  nix = {
    settings.experimental-features = "nix-command flakes";
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
  };

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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHC9Yh1qdHa9rq28Ki0i53vtHgg9ksKq8vg9M+9GGPA5" # etw
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOssvEhZ5BG96yH4fsjYhY6xKt3AKyuyAD5TXapdQUw" # lemurseven
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOaJJvOUG08qr3yeeQRB71M30cdPMuO69nsf0CodALa" # jaysa
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHPeJeRNwcPaZupbmCEtUIOuLDfhow35byMp548TUDYP" # rjz
  ];

  programs.ssh = {
    package = pkgs.openssh_gssapi;
    extraConfig = ''
      CanonicalizeHostname yes
      CanonicalDomains ocf.berkeley.edu
      Host *.ocf.berkeley.edu *.ocf.io 169.229.226.* 2607:f140:8801::*
          GSSAPIAuthentication yes
          GSSAPIKeyExchange yes
          GSSAPIDelegateCredentials no
    '';
  };

  environment.enableAllTerminfo = true;
  environment.systemPackages = with pkgs; [
    # Shells
    bash
    zsh
    fish
    xonsh
    zsh-powerlevel10k

    # System utilities
    dnsutils
    cpufrequtils
    pulseaudio
    pciutils
    usbutils
    cups

    # Monitoring utilities
    s-tui
    htop
    lsof

    # Languages
    (python312.withPackages (ps: [ ps.ocflib ]))
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

    # Networking tools
    rsync
    wget
    curl

    # File management tools
    bar
    zip
    unzip
    _7zz
    eza
    file
    tree

    # Other tools
    ocf.utils
    tmux
    screen
    git
    comma

    # Cosmetics
    neofetch
    pfetch-rs
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
    zsh = {
      enable = true;

      shellInit = ''
        if [[ ! -f ~/.zshrc ]]; then
          source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
          source /etc/p10k.zsh
        fi
        zsh-newuser-install() { :; }
      '';
    };

    fish.enable = true;
    xonsh.enable = true;
    nix-ld.enable = true;
  };

  networking.firewall.enable = false;

  environment.etc = {
    "p10k.zsh".source = ./base/p10k.zsh;

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

  environment.etc."nixos/configuration.nix".text = ''
    {}: builtins.abort "This machine is not managed by /etc/nixos. Please use colmena instead."
  '';
}
