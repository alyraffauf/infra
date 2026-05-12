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

    zone = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "cloud-hetzner";
      description = ''
        Failure domain for this node. Emitted as the standard k8s
        topology.kubernetes.io/zone label so Longhorn replica scheduling and
        topologySpreadConstraints can spread workloads across providers and
        on-prem machines. Current values in use: home, cloud-hetzner,
        cloud-netcup.
      '';
    };

    ingress = lib.mkEnableOption ''
      cute.haus/ingress=true node label. Traefik runs on nodes with this
      label; set true on any node that should serve public HTTP(S)/SSH
      ingress (needs ports 80/443/2222 open at the firewall).
    '';
  };

  config = lib.mkIf cfg.enable {
    # systemd-oomd fights kubelet's eviction manager
    systemd.oomd.enable = lib.mkForce false;

    # Traefik DaemonSet binds these hostPorts on every ingress-labeled node.
    # 80/443 = HTTP(S), 2222 = forgejo SSH (see k8s/helmfile.yaml traefik
    # ports config).
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.ingress [80 443 2222];

    services = {
      k3s = {
        enable = true;
        inherit (cfg) role clusterInit;
        serverAddr = lib.mkIf (cfg.serverAddr != null) cfg.serverAddr;
        tokenFile = config.sops.secrets.k3s.path;
        extraFlags =
          ["--flannel-iface=tailscale0"]
          ++ lib.optionals (cfg.role == "server") (
            [
              "--service-node-port-range=8000-32767"
              "--disable=traefik"
              "--disable=servicelb"
            ]
            ++ map (san: "--tls-san=${san}") cfg.tlsSans
          )
          ++ lib.optionals cfg.clusterInit [
            "--write-kubeconfig-mode=644"
          ]
          ++ lib.optionals (cfg.zone != null) [
            "--node-label=topology.kubernetes.io/zone=${cfg.zone}"
          ]
          ++ lib.optionals cfg.ingress [
            "--node-label=cute.haus/ingress=true"
          ];
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

      services = {
        # Block k3s startup until tailscale0 has its IP — flannel-iface=tailscale0
        # otherwise races and etcd peer setup fails on cold boot.
        k3s = {
          after = ["tailscaled.service"];
          wants = ["tailscaled.service"];
          serviceConfig.ExecStartPre = pkgs.writeShellScript "wait-tailscale0" ''
            until ${pkgs.iproute2}/bin/ip -4 addr show tailscale0 | grep -q inet; do
              ${pkgs.coreutils}/bin/sleep 1
            done
          '';
        };

        # Without this, reboots hang ~5min: k3s stops, the longhorn engine pod
        # on this node dies → kernel iSCSI session sees a connection error,
        # udev spawns scsi_id against the dead device, scsi_id hangs until its
        # 3min timeout, then systemd-shutdown SIGKILLs everything. Explicitly
        # logging out before iscsid stops lets the kernel close the session
        # gracefully. Ordering: starts after iscsid + before k3s, so on
        # shutdown it stops AFTER k3s (CSI volumes already detached) and
        # BEFORE iscsid (sessions still managable).
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
  };
}
