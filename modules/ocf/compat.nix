{ lib, config, ... }:

let
  cfg = config.ocf.compat;
in
{
  options.ocf.compat = {
    enable = lib.mkEnableOption "Enable compatibility tricks with non-Nix software";
  };

  config = lib.mkIf cfg.enable {
    programs.nix-ld.enable = true;
    services.envfs.enable = true;
  };
}
