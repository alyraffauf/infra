{
  config,
  lib,
  pkgs,
  self,
  ...
}: let
  cfg = config.myNixOs.profile.k3s;
  transportService =
    if cfg.transportInterface == "wg-k3s"
    then "wireguard-wg-k3s.service"
    else "tailscaled.service";
in {
  options.myNixOs.profile.k3s = {
    enable = lib.mkEnableOption "k3s cluster node";

    role = lib.mkOption {
      type = lib.types.enum ["server" "agent"];
      default = "server";
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
    };

    transportInterface = lib.mkOption {
      type = lib.types.str;
      default = "tailscale0";
      description = "Network interface used for k3s node and Flannel traffic.";
    };

    nodeIP = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Address k3s advertises for the Kubernetes node.";
    };

    tlsSans = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "snowpoint"
        "pastoria"
        "jubilife"
        "snowpoint.cute"
        "pastoria.cute"
        "jubilife.cute"
      ];
    };

    zone = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "cloud";
    };

    ingress = lib.mkEnableOption "cute.haus/ingress=true node label";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.k3s = {
      sopsFile = "${self}/secrets/k3s.yaml";
      key = "TOKEN";
    };

    # systemd-oomd fights kubelet's eviction manager
    systemd.oomd.enable = lib.mkForce false;

    networking.firewall = {
      allowedTCPPorts = lib.mkIf cfg.ingress [80 443 2222];

      # Let a pod reach kubelet:10250 on its own host. Same-node traffic to
      # the node's Tailscale IP is delivered locally and arrives via cni0, so
      # metrics-server can't scrape the node it runs on without this.
      trustedInterfaces = ["cni0"];
    };

    services = {
      k3s = {
        enable = true;
        inherit (cfg) role clusterInit;
        serverAddr = lib.mkIf (cfg.serverAddr != null) cfg.serverAddr;
        tokenFile = config.sops.secrets.k3s.path;
        extraFlags =
          [
            "--flannel-iface=${cfg.transportInterface}"
            # Keep image storage below Longhorn's 75% disk-use ceiling.
            "--kubelet-arg=image-gc-high-threshold=70"
            "--kubelet-arg=image-gc-low-threshold=65"
          ]
          ++ lib.optionals (cfg.nodeIP != null) ["--node-ip=${cfg.nodeIP}"]
          ++ lib.optionals (cfg.role == "server") (
            [
              "--service-node-port-range=8000-32767"
              "--disable=traefik"
              "--disable=servicelb"
            ]
            ++ lib.optionals (cfg.nodeIP != null) ["--advertise-address=${cfg.nodeIP}"]
            ++ map (san: "--tls-san=${san}") cfg.tlsSans
          )
          ++ lib.optionals cfg.clusterInit ["--write-kubeconfig-mode=644"]
          ++ lib.optionals (cfg.zone != null) ["--node-label=topology.kubernetes.io/zone=${cfg.zone}"]
          ++ lib.optionals cfg.ingress ["--node-label=cute.haus/ingress=true"];
      };

      openiscsi = {
        enable = true;
        name = "iqn.2026-05.haus.cute:${config.networking.hostName}";
      };
    };

    environment.systemPackages = with pkgs; [
      kubernetes-helm
      nfs-utils
    ];

    systemd = {
      # Longhorn instance-manager looks for binaries in /usr/local/bin
      tmpfiles.rules = [
        "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
      ];

      services = {
        # Block k3s startup until its transport interface has an IP. This
        # prevents Flannel and etcd peer setup from racing at cold boot.
        k3s = {
          after = [transportService];
          wants = [transportService];
          serviceConfig.ExecStartPre = pkgs.writeShellScript "wait-k3s-transport" ''
            until ${pkgs.iproute2}/bin/ip -4 addr show ${cfg.transportInterface} | grep -q inet; do
              ${pkgs.coreutils}/bin/sleep 1
            done
          '';
        };

        # Cleanly log out iSCSI sessions at shutdown so reboots don't hang
        # waiting for udev scsi_id timeouts against dead longhorn devices.
        iscsi-logout = {
          description = "Log out iSCSI sessions cleanly at shutdown";
          after = ["iscsid.service"];
          before = ["k3s.service"];
          requires = ["iscsid.service"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.coreutils}/bin/true";
            ExecStop = "-${pkgs.openiscsi}/bin/iscsiadm -m node -u";
            TimeoutStopSec = "30s";
          };
        };
      };
    };
    myNixOs.profile.backups.jobs.k3s = lib.mkIf (cfg.enable && config.myNixOs.profile.backups.enable && config.services.k3s.role == "server") {
      backupPrepareCommand = "${config.services.k3s.package}/bin/k3s etcd-snapshot save";
      paths = [
        "/var/lib/rancher/k3s/server/db/snapshots"
        "/var/lib/rancher/k3s/server/cred"
        "/var/lib/rancher/k3s/server/tls"
      ];
    };
  };
}
