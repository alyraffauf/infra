{self, ...}: {
  flake.modules.nixos.k3s-node = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.myK3s;
  in {
    options.myK3s = {
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

      tlsSans = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["snowpoint" "eterna" "pastoria"];
      };

      zone = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "cloud-hetzner";
      };

      ingress = lib.mkEnableOption "cute.haus/ingress=true node label";
    };

    config = {
      sops.secrets.k3s = {
        sopsFile = "${self}/secrets/k3s.yaml";
        key = "TOKEN";
      };

      # systemd-oomd fights kubelet's eviction manager
      systemd.oomd.enable = lib.mkForce false;

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
        helmfile
        kubernetes-helm
        nfs-utils
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
    };
  };

  flake.modules.nixos.backups = {
    config,
    lib,
    ...
  }: {
    config.myBackups.jobs.k3s = lib.mkIf (config.services.k3s.enable && config.services.k3s.role == "server") {
      backupPrepareCommand = "${config.services.k3s.package}/bin/k3s etcd-snapshot save";
      paths = [
        "/var/lib/rancher/k3s/server/db/snapshots"
        "/var/lib/rancher/k3s/server/cred"
        "/var/lib/rancher/k3s/server/tls"
      ];
    };
  };
}
