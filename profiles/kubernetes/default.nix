{ config, pkgs, lib, ... }:

let
  kubePkgs = with pkgs; [ kubernetes util-linux iproute2 ethtool containerd runc iptables-legacy socat conntrack-tools gvisor cri-tools ebtables ];
in {
  # Configuration for Nodes
  options.services.ocfKubernetes = {
    enable = lib.mkEnableOption "Enables everything needed to run kubeadm.";
    isLeader = lib.mkOption {
      default = false;
      example = true;
      description = "Currently identical to worker, but enables kube-vip as a static pod.";
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.services.ocfKubernetes.enable {
    environment.etc = {
      "kubernetes/manifests/kubevip.yaml".source = lib.mkIf config.services.ocfKubernetes.isLeader ./kubevip.yaml;
      "kubernetes/kubeadm.yaml".source = ./kubeadm.yaml;
    };

    boot.kernelModules = [
      "aes"
      "algif_hash"
      "br_netfilter"
      "ceph"
      "cls_bpf"
      "cryptd"
      "encrypted_keys"
      "ip_tables"
      "iptable_mangle"
      "iptable_raw"
      "iptable_filter"
      "ip6_tables"
      "ip6table_filter"
      "ip6table_mangle"
      "ip6table_raw"
      "ip_set"
      "ip_set_hash_ip"
      "rbd"
      "sch_fq"
      "sha1"
      "sha256"
      "xt_CT"
      "xt_TPROXY"
      "xt_mark"
      "xt_set"
      "xt_socket"
      "xts"
    ];

    # <https://docs.cilium.io/en/stable/operations/system_requirements/#mounted-ebpf-filesystem>
    fileSystems."/sys/fs/bpf" = {
      device = "bpffs";
      fsType = "bpf";
    };

    networking.firewall.allowedTCPPorts = [
      # <https://kubernetes.io/docs/reference/ports-and-protocols/>
      6443 2379 2380 10250 10259 10257 10250
      # <https://docs.cilium.io/en/v1.11/operations/system_requirements/#firewall-rules>
      4240
    ];
    # <https://docs.cilium.io/en/v1.11/operations/system_requirements/#firewall-rules>
    networking.firewall.allowedUDPPorts = [ 8472 ];
    # <https://kubernetes.io/docs/reference/ports-and-protocols/>
    networking.firewall.allowedTCPPortRanges = [ { from = 30000; to = 32767; } ];

    # <https://github.com/NixOS/nixpkgs/issues/179741>
    networking.nftables.enable = false;
    networking.firewall.package = pkgs.iptables-legacy;

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;  
      "net.ipv6.conf.all.forwarding" = 1;
      "net.bridge.bridge-nf-call-iptables" = 1;
      "net.bridge.bridge-nf-call-ip6tables" = 1;
    };

    environment.systemPackages = kubePkgs;

    virtualisation.containerd.enable = true;
    systemd.services.containerd.path = kubePkgs;
    virtualisation.containerd.settings = {
      plugins."io.containerd.grpc.v1.cri" = {
        # <https://docs.cilium.io/en/v1.12/concepts/kubernetes/configuration/#cni>
        cni.bin_dir = "/opt/cni/bin";
        cni.conf_dir = "/etc/cni/net.d";
        # <https://github.com/containerd/containerd/blob/main/docs/cri/config.md#runtime-classes>
        containerd.default_runtime_name = "crun";
        containerd.runtimes.runc.runtime_type = "io.containerd.runc.v2";
        containerd.runtimes.crun.runtime_type = "io.containerd.runc.v2";
        plugins."io.containerd.grpc.v1.cri".containerd.runtimes.crun.options.BinaryName = "${pkgs.crun}/bin/crun";
        containerd.runtimes.gvisor.runtime_type = "io.containerd.runsc.v1";
        # <https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd>
        containerd.runtimes.runc.options.SystemdCgroup = true;
      };
    };

    systemd.services.kubelet = {
      description = "Kubelet <https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/>";
      wantedBy = [ "multi-user.target" ];

      path = kubePkgs;

      serviceConfig = {
        StateDirectory = "kubelet";
        ConfiguratonDirectory = "kubernetes";

        # KUBELET_KUBEADM_ARGS - generated by kubeadm
        EnvironmentFile = "-/var/lib/kubelet/kubeadm-flags.env";

        Restart = "always";
        StartLimitIntervalSec = 0;
        RestartSec = 10;

        ExecStart = ''
          ${pkgs.kubernetes}/bin/kubelet \
            --kubeconfig=/etc/kubernetes/kubelet.conf \
            --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
            --config=/var/lib/kubelet/config.yaml \
            $KUBELET_KUBEADM_ARGS
        '';
      };
    };
  };
}
