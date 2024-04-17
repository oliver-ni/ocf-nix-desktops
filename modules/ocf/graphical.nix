{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.ocf.graphical;
in
{
  options.ocf.graphical = {
    enable = mkEnableOption "Enable desktop environment configuration";
  };

  config = mkIf cfg.enable {
    security.pam = {
      services.systemd-user.makeHomeDir = true;
      makeHomeDir.skelDirectory = "/etc/skel";
    };

    boot = {
      loader.timeout = 0;

      initrd = {
        verbose = false;
        systemd.enable = true;
      };

      consoleLogLevel = 0;
      kernelParams = [ "quiet" "udev.log_level=3" ];
    };

    environment.etc = {
      skel.source = ./graphical/skel;
      "ocf-assets".source = ./graphical/assets;
    };

    programs.steam.enable = true;

    environment.systemPackages = with pkgs; [
      pkgs.ocf.plasma-applet-commandoutput
      (pkgs.ocf.catppuccin-sddm.override {
        themeConfig.General = {
          FontSize = 12;
          Background = "/etc/ocf-assets/images/login.png";
          Logo = "/etc/ocf-assets/images/penguin.svg";
          CustomBackground = true;
        };
      })
      google-chrome
      firefox
      libreoffice
      vscode-fhs
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
