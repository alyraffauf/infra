{
  config,
  modulesPath,
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
    firewall.allowedTCPPorts = [2222 8282];
    hostName = "solaceon";
  };

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = [
      "--write-kubeconfig-mode=644"
      "--service-node-port-range=8000-32767"
    ];

    autoDeployCharts.aly-codes = {
      package = ../../charts/aly-codes;
      targetNamespace = "default";
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
      caddy.enable = true;

      forgejo = {
        enable = true;
        db = "postgresql";
      };

      prometheusNode.enable = true;
      promtail.enable = true;
      tailscale.enable = true;
      watsup.enable = true;
    };
  };

  myUsers.root.enable = true;
}
