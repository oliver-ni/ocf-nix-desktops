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

      links."10-${cfg.interface}" = {
        matchConfig.OriginalName = cfg.interface;
        linkConfig.WakeOnLan = "magic";
      };

      networks."10-${cfg.interface}" = {
        matchConfig.Name = cfg.interface;
        linkConfig.RequiredForOnline = "routable";
        address = [
          "169.229.226.${toString cfg.lastOctet}/24"
          "2607:f140:8801::1:${toString cfg.lastOctet}/64"
        ];
        routes = [
          { routeConfig.Gateway = "169.229.226.1"; }
          { routeConfig.Gateway = "2607:f140:8801::1"; }
        ];
        dns = [
          "169.229.226.22"
          "2607:f140:8801::1:22"
          "1.1.1.1"
        ];
        domains = [ "ocf.berkeley.edu" "ocf.io" ];
      };
    };
  };
}
