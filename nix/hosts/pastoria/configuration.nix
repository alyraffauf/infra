{
  inputs,
  self,
  ...
}: [
  self.nixosModules.myHw
  self.nixosModules.myNixOs
  self.nixosModules.myDisko

  {
    myNixOs = {
      profile = {
        backups.enable = true;
        base.enable = true;
        k3s.enable = true;
        localeEnUs.enable = true;
        swap.enable = true;
        vps.enable = true;
        wireguardK3s.enable = true;
      };

      program.docker.enable = true;

      service = {
        alloy.enable = true;
        fail2ban.enable = true;
        prometheusNode.enable = true;
        tailscale.enable = true;
      };
    };

    myDisko.profile.lvmExt4.enable = true;
  }

  inputs.disko.nixosModules.disko
  inputs.sops-nix.nixosModules.sops
  ({
    modulesPath,
    pkgs,
    ...
  }: {
    imports = ["${modulesPath}/profiles/qemu-guest.nix"];

    boot.loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };

    networking = {
      firewall.allowedTCPPorts = [23];
      hostName = "pastoria";
    };

    nixpkgs.hostPlatform = "x86_64-linux";
    system = {
      stateVersion = "26.05";
      autoUpgrade.dates = "01:45";
    };

    myDisko.installDrive = "/dev/sda";

    systemd.services.atbbs-telnet = {
      description = "TCP proxy for atbbs telnet";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:23,fork,reuseaddr TCP:jubilife:2323";
        Restart = "always";
      };
    };

    myNixOs.profile = {
      k3s = {
        role = "server";
        serverAddr = "https://snowpoint.cute:6443";
        transportInterface = "wg-k3s";
        nodeIP = "10.254.0.2";
        zone = "cloud";
        ingress = true;
      };
      swap.size = 4096;
    };
  })

  {
    nixpkgs = {
      overlays = [self.overlays.default];
      config.allowUnfree = true;
    };
  }
]
