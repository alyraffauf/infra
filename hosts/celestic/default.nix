{
  config,
  modulesPath,
  pkgs,
  self,
  ...
}: {
  imports = [
    # ./anubis.nix
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

  networking = {
    firewall.allowedTCPPorts = [23 80 443];
    hostName = "celestic";
  };

  services.k3s = {
    enable = true;
    role = "server";
    serverAddr = "https://solaceon:6443";
    tokenFile = config.age.secrets.k3s.path;
    extraFlags = [
      "--flannel-iface=tailscale0"
      "--tls-san=solaceon"
      "--service-node-port-range=8000-32767"
      "--disable=traefik"
      "--disable=servicelb"
    ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  programs.ssh.knownHosts = config.mySnippets.ssh.knownHosts;
  system.stateVersion = "25.11";

  systemd.services.atbbs-telnet = {
    description = "TCP proxy for atbbs telnet";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:23,fork,reuseaddr TCP:${config.mySnippets.cute-haus.networkMap.atbbs.hostName}:2323";
      Restart = "always";
    };
  };

  time.timeZone = "America/New_York";
  myDisko.installDrive = "/dev/sda";

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
      prometheusNode.enable = true;
      promtail.enable = true;
      tailscale.enable = true;
    };
  };

  myUsers.root.enable = true;
}
