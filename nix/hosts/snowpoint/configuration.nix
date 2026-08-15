{
  inputs,
  self,
  ...
}: [
  self.nixosModules.myNixOs
  self.nixosModules.myDisko

  {
    hardware.facter.reportPath = ./facter.json;
  }

  {
    myNixOs = {
      profile = {
        backups.enable = true;
        base.enable = true;
        dataShare.enable = true;
        k3s.enable = true;
        localeEnUs.enable = true;
        mediaShare.enable = true;
        observability.enable = true;
        swap.enable = true;
        vps.enable = true;
        wireguardK3s.enable = true;
      };
      service = {
        alloy.enable = true;
        cachefilesd.enable = true;
        fail2ban.enable = true;
        prometheusNode.enable = true;
        syncthing.enable = true;
        tailscale.enable = true;
      };
      users.aly.enable = true;
    };
    myDisko.profile.lvmExt4.enable = true;
  }

  inputs.disko.nixosModules.disko
  inputs.sops-nix.nixosModules.sops
  ({
    modulesPath,
    config,
    self,
    ...
  }: {
    imports = ["${modulesPath}/profiles/qemu-guest.nix"];

    boot.loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };

    fileSystems = {};
    networking.hostName = "snowpoint";
    nixpkgs.hostPlatform = "x86_64-linux";
    system = {
      stateVersion = "25.11";
      autoUpgrade.dates = "03:30";
    };

    sops.secrets = {
      syncthingCert = {
        sopsFile = "${self}/secrets/syncthing.yaml";
        key = "snowpoint_cert";
      };
      syncthingKey = {
        sopsFile = "${self}/secrets/syncthing.yaml";
        key = "snowpoint_key";
      };
    };

    services.qemuGuest.enable = true;
    myDisko.installDrive = "/dev/vda";

    myNixOs = {
      profile.k3s = {
        role = "server";
        serverAddr = "https://pastoria.cute:6443";
        transportInterface = "wg-k3s";
        nodeIP = "10.254.0.3";
        zone = "cloud";
        ingress = true;
      };
      service.syncthing = {
        certFile = config.sops.secrets.syncthingCert.path;
        keyFile = config.sops.secrets.syncthingKey.path;
        syncROMs = false;
        user = "aly";
      };
      users.aly.password = "$6$JTk2qi27OpA2fOAY$ZgTDg0wbmbwHUD..0xT4xYX.AR5hWQFCMVmn8G88yi3IAY7015AupovTpfy0arkI7nl/IDu5L09bzLKeXGvJC1";
    };
  })

  {
    nixpkgs = {
      overlays = [self.overlays.default];
      config.allowUnfree = true;
    };
  }
]
