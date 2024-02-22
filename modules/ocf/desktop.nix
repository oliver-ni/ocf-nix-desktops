{ lib, config, ... }:

with lib;
let
  cfg = config.ocf.desktop;
in
{
  options.ocf.desktop = {
    enable = mkEnableOption "Enable OCF desktop environment configuration";
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      desktopManager.plasma5.enable = true;

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
