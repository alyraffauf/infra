{
  config,
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.snowpoint = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      fail2ban
      flake-url
      known-hosts
      locale-en-us
      njust
      recipes
      performance
      ssh-keys
      users
      alloy
      auto-upgrade
      b2-mounts
      backups
      cachefilesd
      data-share
      k3s-node
      media-share
      nix-config
      plex
      prometheus-node
      swap
      syncthing
      tailscale
      vps

      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      config.flake.diskoConfigurations.lvm-ext4
      (
        {config, ...}: {
          boot = {
            initrd = {
              availableKernelModules = [
                "virtio_net"
                "virtio_pci"
                "virtio_mmio"
                "virtio_blk"
                "virtio_scsi"
                "9p"
                "9pnet_virtio"
              ];

              kernelModules = [
                "virtio_balloon"
                "virtio_console"
                "virtio_rng"
                "virtio_gpu"
              ];
            };

            loader.grub = {
              efiSupport = true;
              efiInstallAsRemovable = true;
            };
          };

          fileSystems = {};

          networking.hostName = "snowpoint";
          nixpkgs.hostPlatform = "x86_64-linux";
          system.stateVersion = "25.11";

          sops.secrets = {
            navidrome = {
              sopsFile = ../../secrets/navidrome.yaml;
              key = "env";
            };
            syncthingCert = {
              sopsFile = ../../secrets/syncthing.yaml;
              key = "snowpoint_cert";
            };
            syncthingKey = {
              sopsFile = ../../secrets/syncthing.yaml;
              key = "snowpoint_key";
            };
          };

          services = {
            qemuGuest.enable = true;

            navidrome = {
              enable = true;
              environmentFile = config.sops.secrets.navidrome.path;

              settings = {
                Address = "0.0.0.0";
                DefaultTheme = "Auto";
                EnableUserEditing = false;
                MusicFolder = "/mnt/Media/Music";
                Port = 4533;
                SubsonicArtistParticipations = true;
                UIWelcomeMessage = "Welcome to Navidrome @ ${config.networking.hostName}";

                # SSO via traefik-forward-auth in the cluster (auth.cute.haus).
                # TrustedSources is checked against the immediate TCP source — the
                # traefik pod inside the k3s pod CIDR — not against X-Forwarded-For.
                # Subsonic mobile clients hit caddy directly from the tailnet and
                # don't send the header; they fall back to local username/password.
                ExtAuth = {
                  UserHeader = "X-Forwarded-User";
                  TrustedSources = builtins.concatStringsSep "," [
                    "100.64.0.0/10"
                    "10.42.0.0/16"
                  ];
                };
              };
            };
          };

          systemd.services.navidrome.serviceConfig = {
            Restart = "on-failure";
            RestartSec = "30s";
          };
          myDisko.installDrive = "/dev/vda";

          myAutoUpgrade.dates = "03:30";

          myB2Mounts.cacheDir = "/mnt/Backblaze/.rclone-cache";

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
