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

  systemd.services = let
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
    k3s-aly-codes-tls = mkTlsSync "aly-codes";
    k3s-aly-social-tls = mkTlsSync "aly-social";
    k3s-cute-haus-tls = mkTlsSync "cute-haus";
    k3s-morsels-blue-tls = mkTlsSync "morsels-blue";
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

      k3s = {
        enable = true;
        role = "server";
        clusterInit = true;
        tlsSans = ["celestic" "eterna"];
      };

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
