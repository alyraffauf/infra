{
  inputs,
  self,
  ...
}: [
  self.nixosModules.myNixOs

  {
    hardware.facter.reportPath = ./facter.json;
  }

  ./base.nix

  inputs.disko.nixosModules.disko
  inputs.sops-nix.nixosModules.sops
  (
    {config, ...}: {
      fileSystems."/mnt/Storage" = {
        device = "/dev/disk/by-id/ata-CT2000BX500SSD1_2345E8842829";
        fsType = "btrfs";
        options = ["compress=zstd" "noatime" "nofail"];
      };

      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [2049];
          allowedUDPPorts = [2049];
        };

        hostName = "eterna";
      };

      services.nfs.server = {
        enable = true;

        exports = ''
          /mnt/Storage 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,fsid=0)
        '';
      };

      system = {
        autoUpgrade.dates = "05:00";
        stateVersion = "25.11";
      };

      myNixOs = {
        profile = {
          backups.jobs = {
            syncthing-sync = {
              paths = ["/home/aly/sync"];
              repository = "rclone:b2:aly-backups/syncthing/sync";
            };

            syncthing-roms = {
              paths = [config.myNixOs.service.syncthing.romsPath];
              repository = "rclone:b2:aly-backups/syncthing/roms";
            };
          };

          k3s = {
            role = "agent";
            serverAddr = "https://pastoria.cute:6443";
            transportInterface = "wg-k3s";
            nodeIP = "10.254.0.4";
            zone = "home";
            ingress = true;
          };
        };

        service.syncthing = {
          certFile = config.sops.secrets.syncthingCert.path;
          keyFile = config.sops.secrets.syncthingKey.path;
          user = "aly";
        };

        users.aly.password = "$6$JTk2qi27OpA2fOAY$ZgTDg0wbmbwHUD..0xT4xYX.AR5hWQFCMVmn8G88yi3IAY7015AupovTpfy0arkI7nl/IDu5L09bzLKeXGvJC1";
      };

      sops.secrets = {
        syncthingCert = {
          sopsFile = "${self}/secrets/syncthing.yaml";
          key = "eterna_cert";
        };
        syncthingKey = {
          sopsFile = "${self}/secrets/syncthing.yaml";
          key = "eterna_key";
        };
      };
    }
  )

  # disk layout
  {
    disko.devices = {
      disk = {
        vdb = {
          type = "disk";
          device = "/dev/sda";

          content = {
            type = "gpt";

            partitions = {
              ESP = {
                content = {
                  format = "vfat";

                  mountOptions = [
                    "defaults"
                    "umask=0077"
                  ];

                  mountpoint = "/boot";
                  type = "filesystem";
                };

                size = "1024M";
                type = "EF00";
              };

              luks = {
                size = "100%";

                content = {
                  type = "luks";
                  name = "crypted";

                  content = {
                    type = "btrfs";
                    extraArgs = ["-f"];

                    subvolumes = {
                      "/root" = {
                        mountOptions = ["compress=zstd" "noatime"];
                        mountpoint = "/";
                      };

                      "persist" = {
                        mountOptions = ["compress=zstd" "noatime"];
                        mountpoint = "/persist";
                      };

                      "/home" = {
                        mountOptions = ["compress=zstd" "noatime"];
                        mountpoint = "/home";
                      };

                      "/home/.snapshots" = {
                        mountOptions = ["compress=zstd" "noatime"];
                        mountpoint = "/home/.snapshots";
                      };

                      "/nix" = {
                        mountOptions = ["compress=zstd" "noatime"];
                        mountpoint = "/nix";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  }

  # services
  {
    services.caddy.email = "alyraffauf@fastmail.com";
  }

  {
    nixpkgs = {
      overlays = [self.overlays.default];
      config.allowUnfree = true;
    };
  }
]
