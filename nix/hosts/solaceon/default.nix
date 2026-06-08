{
  modulesPath,
  pkgs,
  self,
  ...
}: {
  imports = [
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
    firewall.allowedTCPPorts = [23 8282 8383];
    hostName = "solaceon";
  };

  systemd.services.atbbs-telnet = {
    description = "TCP proxy for atbbs telnet";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:23,fork,reuseaddr TCP:eterna:2323";
      Restart = "always";
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";
  time.timeZone = "America/New_York";
  myDisko.installDrive = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_62292463";

  myNixOS = {
    base.enable = true;

    profiles = {
      autoUpgrade = {
        enable = true;
        dates = "02:00";
      };

      backups.enable = true;

      k3s = {
        enable = true;
        role = "server";
        clusterInit = true;
        tlsSans = ["pastoria" "eterna"];
        zone = "cloud-hetzner";
        ingress = true;
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
      prometheusNode.enable = true;
      alloy.enable = true;
      tailscale.enable = true;
    };
  };

  myUsers.root.enable = true;
}
