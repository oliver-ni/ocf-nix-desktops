{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.ocf.de;
in
{
  options.ocf.de = {
    enable = mkEnableOption "Enable desktop environment configuration";
  };

  config = mkIf cfg.enable {
    security.pam = {
      services.systemd-user.makeHomeDir = true;
      makeHomeDir.skelDirectory = "/etc/skel";
    };

    environment.etc = {
      skel.source = ./de/skel;
      "ocf/assets".source = ./de/assets;
      "p10k.zsh".source = ./de/p10k.zsh;
    };

    programs.zsh.shellInit = ''
      if [[ ! -f ~/.zshrc ]]; then
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source /etc/p10k.zsh
      fi
      zsh-newuser-install() { :; }
    '';

    environment.systemPackages = with pkgs; [
      pkgs.ocf.plasma-applet-commandoutput
      (pkgs.ocf.catppuccin-sddm.override {
        themeConfig.General = {
          FontSize = 12;
          Background = "/etc/ocf/assets/images/login.png";
          Logo = "/etc/ocf/assets/images/penguin-swing.svg";
          CustomBackground = true;
        };
      })
      google-chrome
      firefox
      libreoffice
      vscode-fhs
      zsh-powerlevel10k
      kitty
    ];

    fonts.packages = [ pkgs.meslo-lgs-nf ];

    services.xserver = {
      enable = true;

      # KDE is our primary DE, but have others available
      desktopManager.plasma6.enable = true;
      desktopManager.gnome.enable = true;
      desktopManager.xfce.enable = true;

      displayManager = {
        defaultSession = "plasma";

        sddm = {
          enable = true;
          theme = "catppuccin-latte";
          wayland.enable = true;
          settings.Users = {
            RememberLastUser = false;
            RememberLastSession = false;
          };
        };
      };

      xkb = {
        layout = "us";
        variant = "";
      };
    };

    systemd.user.services.wayout = {
      description = "Automatic idle logout manager";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.ocf.wayout}/bin/wayout";
        Type = "simple";
        Restart = "on-failure";
      };
    };

    # Conflict override since multiple DEs set this option
    programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.ksshaskpass.out}/bin/ksshaskpass";
  };
}
