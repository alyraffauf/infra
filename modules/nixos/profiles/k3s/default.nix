{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myNixOS.profiles.k3s;
in {
  options.myNixOS.profiles.k3s = {
    enable = lib.mkEnableOption "k3s cluster node";

    role = lib.mkOption {
      type = lib.types.enum ["server" "agent"];
      default = "server";
      description = "k3s role for this node.";
    };

    clusterInit = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether this node initializes the cluster's etcd. Exactly one node
        in the cluster should set this. Other servers join via `serverAddr`.
      '';
    };

    serverAddr = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://solaceon:6443";
      description = ''
        URL of the cluster's first server. Required for joining nodes
        (non-init servers and agents); null on the cluster-init node.
      '';
    };

    tlsSans = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["solaceon" "celestic" "eterna"];
      description = "Hostnames to include as TLS SANs on this node's certs.";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      k3s = {
        enable = true;
        inherit (cfg) role clusterInit;
        serverAddr = lib.mkIf (cfg.serverAddr != null) cfg.serverAddr;
        tokenFile = config.age.secrets.k3s.path;
        extraFlags =
          [
            "--flannel-iface=tailscale0"
            "--service-node-port-range=8000-32767"
          ]
          ++ lib.optionals (cfg.role == "server") [
            "--disable=traefik"
            "--disable=servicelb"
          ]
          ++ lib.optionals cfg.clusterInit [
            "--write-kubeconfig-mode=644"
          ]
          ++ map (san: "--tls-san=${san}") cfg.tlsSans;
      };

      # Longhorn prereq
      openiscsi = {
        enable = true;
        name = "iqn.2026-05.haus.cute:${config.networking.hostName}";
      };
    };

    environment.systemPackages = with pkgs; [
      helmfile
      kubernetes-helm
      nfs-utils # Longhorn backup target uses NFS client
    ];

    systemd = {
      # Longhorn instance-manager looks for binaries in /usr/local/bin
      tmpfiles.rules = [
        "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
      ];

      # Block k3s startup until tailscale0 has its IP — flannel-iface=tailscale0
      # otherwise races and etcd peer setup fails on cold boot.
      services.k3s = {
        after = ["tailscaled.service"];
        wants = ["tailscaled.service"];
        serviceConfig.ExecStartPre = pkgs.writeShellScript "wait-tailscale0" ''
          until ${pkgs.iproute2}/bin/ip -4 addr show tailscale0 | grep -q inet; do
            ${pkgs.coreutils}/bin/sleep 1
          done
        '';
      };
    };
  };
}
