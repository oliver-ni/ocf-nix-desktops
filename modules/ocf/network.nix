{ lib, config, ... }:

with lib;
let
  cfg = config.ocf.network;
in
{
  options.ocf.network = {
    enable = mkEnableOption "Enable OCF network configuration";
    interface = mkOption {
      type = types.str;
      description = "Name of the network interface";
    };
    lastOctet = mkOption {
      type = types.int;
      description = "Last octet of the IP address";
    };
  };

  config = mkIf (cfg.enable) {
    networking.useDHCP = false;

    systemd.network = {
      enable = true;

      networks."10-wired" = {
        matchConfig.Name = cfg.interface;
        address = [
          "169.229.226.${toString cfg.lastOctet}/24"
          "2607:f140:8801::1:${toString cfg.lastOctet}/64"
        ];
        routes = [
          { routeConfig.Gateway = "169.229.226.1"; }
          { routeConfig.Gateway = "2607:f140:8801::1"; }
        ];
        domains = [ "ocf.berkeley.edu" "ocf.io" ];
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}
