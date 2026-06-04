{
  modulesPath,
  self,
  ...
}: {
  imports = [
    ./secrets.nix
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

  networking.hostName = "pastoria";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "26.05";
  time.timeZone = "America/New_York";
  myDisko.installDrive = "/dev/sda";

  myNixOS = {
    base.enable = true;

    profiles = {
      autoUpgrade = {
        enable = true;
        dates = "01:45";
      };

      backups.enable = true;

      k3s = {
        enable = true;
        role = "server";
        serverAddr = "https://solaceon:6443";
        tlsSans = ["solaceon" "eterna"];
        zone = "cloud-ovhcloud";
        ingress = false;
      };

      vps.enable = true;

      swap = {
        enable = true;
        size = 4096;
      };

      zram.enable = true;
    };

    programs = {
      nix.enable = true;
      podman.enable = true;
    };

    services = {
      prometheusNode.enable = true;
      alloy.enable = true;
      tailscale.enable = true;
    };
  };

  myUsers.root.enable = true;
}
