{
  config,
  modulesPath,
  pkgs,
  self,
  ...
}: {
  imports = [
    ./secrets.nix
    ./services.nix
    "${modulesPath}/profiles/qemu-guest.nix"
    self.diskoConfigurations.lvm-ext4
    self.nixosModules.locale-en-us
  ];

  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "sd_mod"
      "sr_mod"
      "virtio_pci"
      "virtio_scsi"
      "xhci_pci"
    ];

    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  networking = {
    firewall.allowedTCPPorts = [2222 8282 8383];
    hostName = "solaceon";
  };

  environment.systemPackages = with pkgs; [
    helmfile
    kubernetes-helm
    nfs-utils
  ];

  services = {
    openiscsi = {
      enable = true;
      name = "iqn.2026-05.haus.cute:${config.networking.hostName}";
    };

    k3s = {
      enable = true;
      role = "server";
      clusterInit = true;
      tokenFile = config.age.secrets.k3s.path;
      extraFlags = [
        "--write-kubeconfig-mode=644"
        "--service-node-port-range=8000-32767"
        "--flannel-iface=tailscale0"
        "--tls-san=celestic"
        "--tls-san=eterna"
        "--disable=servicelb"
        "--disable=traefik"
      ];
    };
  };

  systemd = {
    tmpfiles.rules = [
      "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
    ];

    services = let
      mkTlsSync = name: {
        description = "Sync ${name} origin cert into k8s secret";
        after = ["k3s.service"];
        wants = ["k3s.service"];
        wantedBy = ["multi-user.target"];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = 10;
        };

        script = ''
          export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
          until ${pkgs.k3s}/bin/k3s kubectl get nodes >/dev/null 2>&1; do
            sleep 2
          done
          ${pkgs.k3s}/bin/k3s kubectl create secret tls ${name}-tls \
            --cert=${config.age.secrets."${name}-tls-crt".path} \
            --key=${config.age.secrets."${name}-tls-key".path} \
            --dry-run=client -o yaml \
            | ${pkgs.k3s}/bin/k3s kubectl apply -f -
        '';
      };
    in {
      k3s = {
        after = ["tailscaled.service"];
        wants = ["tailscaled.service"];
        serviceConfig.ExecStartPre = pkgs.writeShellScript "wait-tailscale0" ''
          until ${pkgs.iproute2}/bin/ip -4 addr show tailscale0 | grep -q inet; do
            ${pkgs.coreutils}/bin/sleep 1
          done
        '';
      };

      k3s-aly-codes-tls = mkTlsSync "aly-codes";
      k3s-aly-social-tls = mkTlsSync "aly-social";
      k3s-cute-haus-tls = mkTlsSync "cute-haus";
      k3s-morsels-blue-tls = mkTlsSync "morsels-blue";
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  programs.ssh.knownHosts = config.mySnippets.ssh.knownHosts;
  system.stateVersion = "25.11";
  time.timeZone = "America/New_York";
  myDisko.installDrive = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_62292463";

  myNixOS = {
    base.enable = true;

    profiles = {
      autoUpgrade.enable = true;
      backups.enable = true;
      vps.enable = true;

      swap = {
        enable = true;
        size = 2048;
      };

      zram.enable = true;
    };

    programs = {
      nix.enable = true;
      podman.enable = true;
    };

    services = {
      forgejo = {
        enable = true;
        db = "postgresql";
      };

      prometheusNode.enable = true;
      promtail.enable = true;

      tailscale = {
        enable = true;
        enableCaddy = false;
      };
    };
  };

  myUsers.root.enable = true;
}
