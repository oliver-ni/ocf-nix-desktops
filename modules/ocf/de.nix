{ lib, config, ... }:

with lib;
let
  cfg = config.ocf.de;
in
{
  options.ocf.de = {
    enable = mkEnableOption "Enable desktop environment configuration";
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;

      # KDE is our primary DE, but have others available
      desktopManager.plasma5.enable = true;
      desktopManager.gnome.enable = true;
      desktopManager.xfce.enable = true;

      displayManager = {
        defaultSession = "plasmawayland";
        lightdm = {
          enable = true;
          greeters.gtk = {
            enable = true;
            # theme.name = "breeze";
            # iconTheme.name = "breeze";
            # cursorTheme.name = "breeze_cursors";
            # indicators = [ "~host" "~spacer" "~clock" "~spacer" "~layout" "~language" "~session" "~ally" "~power" ];
          };
        };
      };
    };
  };
}
