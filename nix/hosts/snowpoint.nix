{
  config,
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.snowpoint = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      alloy
      backups
      base
      cachefilesd
      data-share
      fail2ban
      k3s-node
      locale-en-us
      media-share
      plex
      prometheus-node
      swap
      syncthing
      tailscale
      users-aly
      vps

      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      config.flake.diskoConfigurations.lvm-ext4
      (
        {
          modulesPath,
          config,
          ...
        }: {
          imports = [
            "${modulesPath}/profiles/qemu-guest.nix"
          ];

          boot.loader.grub = {
            efiSupport = true;
            efiInstallAsRemovable = true;
          };

          fileSystems = {};
          networking.hostName = "snowpoint";
          nixpkgs.hostPlatform = "x86_64-linux";
          system.stateVersion = "25.11";

          sops.secrets = {
            syncthingCert = {
              sopsFile = ../../secrets/syncthing.yaml;
              key = "snowpoint_cert";
            };

            syncthingKey = {
              sopsFile = ../../secrets/syncthing.yaml;
              key = "snowpoint_key";
            };
          };

          services.qemuGuest.enable = true;
          myDisko.installDrive = "/dev/vda";
          system.autoUpgrade.dates = "03:30";

          myK3s = {
            role = "agent";
            serverAddr = "https://pastoria:6443";
            zone = "cloud-netcup";
            ingress = true;
          };

          mySyncthing = {
            certFile = config.sops.secrets.syncthingCert.path;
            keyFile = config.sops.secrets.syncthingKey.path;
            syncROMs = false;
            user = "aly";
          };

          myUsers.aly.password = "$6$JTk2qi27OpA2fOAY$ZgTDg0wbmbwHUD..0xT4xYX.AR5hWQFCMVmn8G88yi3IAY7015AupovTpfy0arkI7nl/IDu5L09bzLKeXGvJC1";
        }
      )

      {
        nixpkgs = {
          overlays = [self.overlays.default];
          config.allowUnfree = true;
        };
      }
    ];
  };
}
