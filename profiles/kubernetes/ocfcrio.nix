{ config, lib, pkgs, utils, ... }:

with lib;
let
  cfg = config.ocf.cri-o;
  crioPackage = (pkgs.cri-o.override { inherit (cfg) extraPackages; });
  format = pkgs.formats.toml { };
  cfgFile = format.generate "00-nix.conf" cfg.settings;
in
{
  meta = {
    maintainers = teams.podman.members;
  };

  options.ocf.cri-o = {
    enable = mkEnableOption (lib.mdDoc "Container Runtime Interface for OCI (CRI-O) - OCF Package");

    extraPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = literalExpression ''
        [
          pkgs.gvisor
        ]
      '';
      description = lib.mdDoc ''
        Extra packages to be installed in the CRI-O wrapper.
      '';
    };

    package = mkOption {
      type = types.package;
      default = crioPackage;
      internal = true;
      description = lib.mdDoc ''
        The final CRI-O package (including extra packages).
      '';
    };

    settings = mkOption {
      type = format.type;
      default = { };
      description = lib.mdDoc ''
        Configuration for cri-o, see
        <https://github.com/cri-o/cri-o/blob/master/docs/crio.conf.5.md>.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package pkgs.cri-tools ];

    environment.etc."crictl.yaml".source = utils.copyFile "${pkgs.cri-o-unwrapped.src}/crictl.yaml";
    environment.etc."crio/crio.conf.d/00-nix.conf".source = cfgFile;

    # Enable common /etc/containers configuration
    virtualisation.containers.enable = true;

    systemd.services.crio = {
      description = "Container Runtime Interface for OCI (CRI-O) (OCF Custom Package)";
      documentation = [ "https://github.com/cri-o/cri-o" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ cfg.package ];
      serviceConfig = {
        Type = "notify";
        ExecStart = "${cfg.package}/bin/crio";
        ExecReload = "/bin/kill -s HUP $MAINPID";
        TasksMax = "infinity";
        LimitNOFILE = "1048576";
        LimitNPROC = "1048576";
        LimitCORE = "infinity";
        OOMScoreAdjust = "-999";
        TimeoutStartSec = "0";
        Restart = "on-abnormal";
      };
      restartTriggers = [ cfgFile ];
    };
  };
}
