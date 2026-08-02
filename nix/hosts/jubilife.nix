{
  config,
  inputs,
  self,
  ...
}: let
  tnet = "narwhal-snapper.ts.net";
  dataDirectory = "/mnt/Data";
  k3sPodCidr = "10.42.0.0/16";
in {
  flake.nixosConfigurations.jubilife = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      alloy
      amd-cpu
      arr
      b2-mounts
      backups
      base
      btrfs
      caddy
      fail2ban
      forgejo-runner
      intel-gpu
      k3s-node
      lanzaboote
      locale-en-us
      podman
      prometheus-node
      qbittorrent
      swap
      syncthing
      tailscale
      tautulli
      users-aly
      vps
      wireguard-k3s

      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      config.flake.diskoConfigurations.luks-btrfs-subvolumes
      (
        {
          config,
          pkgs,
          ...
        }: {
          boot = {
            initrd.availableKernelModules = ["r8169"];
            kernelModules = ["sg"];
          };

          environment.systemPackages = with pkgs; [
            abcde
            age
            chezmoi
            claude-code
            codex
            curl
            delta
            eza
            ffmpeg-full
            flac
            fzf
            gh
            handbrake
            lazygit
            makemkv
            mediainfo
            mkvtoolnix
            opencode
            rclone
            restic
            ripgrep
            starship
            zoxide
          ];

          fileSystems = {
            "/mnt/Data" = {
              device = "/dev/disk/by-id/ata-CT4000BX500SSD1_2447E9959972";
              fsType = "btrfs";
              options = ["compress=zstd" "noatime" "nofail"];
            };

            "/mnt/Media" = {
              device = "/dev/disk/by-id/ata-ST14000NM001G-2KJ103_ZL201XNJ-part1";
              fsType = "btrfs";
              options = ["subvol=@media" "compress=zstd" "noatime" "nofail"];
            };
          };

          networking = {
            firewall.allowedTCPPorts = [2342 5143 6881];
            hostName = "jubilife";
          };

          system.stateVersion = "25.11";
          myDisko.installDrive = "/dev/disk/by-id/nvme-PNY_CS2130_1TB_SSD_PNY211821050701050CC";

          myArr.dataDir = "/mnt/Data";
          system.autoUpgrade.dates = "04:15";

          myB2Mounts = {
            cacheDir = "/mnt/Data/.rclone-cache";
            audioCacheSize = "50G";
            audioReadAhead = "3G";
            videoCacheSize = "300G";
            videoReadAhead = "5G";
          };

          myForgejoRunner = {
            dockerContainers = 3;
            nativeRunners = 2;
          };

          myK3s = {
            role = "server";
            clusterInit = true;
            zone = "home";
          };

          myWireguardK3s.enable = true;

          mySyncthing = {
            certFile = config.sops.secrets.syncthingCert.path;
            keyFile = config.sops.secrets.syncthingKey.path;
            romsPath = "${dataDirectory}/syncthing/ROMs";
            syncROMs = true;
            user = "aly";
          };

          sops.secrets = {
            syncthingCert = {
              sopsFile = ../../secrets/syncthing.yaml;
              key = "jubilife_cert";
            };
            syncthingKey = {
              sopsFile = ../../secrets/syncthing.yaml;
              key = "jubilife_key";
            };
          };

          myUsers.aly.password = "$6$JTk2qi27OpA2fOAY$ZgTDg0wbmbwHUD..0xT4xYX.AR5hWQFCMVmn8G88yi3IAY7015AupovTpfy0arkI7nl/IDu5L09bzLKeXGvJC1";
        }
      )

      # containers
      {
        myBackups.jobs.dizquetv.paths = ["/mnt/Data/dizquetv"];

        systemd.tmpfiles.rules = [
          "d /mnt/Data/dizquetv 0755 root root"
          "d /mnt/Data/arm/home 0755 1000 1000 - -"
          "d /mnt/Data/arm/config 0755 1000 1000 - -"
          "d /mnt/Data/arm 0755 1000 1000 - -"
          "d /mnt/Data/jellyfin 0700 1000 1000 - -"
          "d /mnt/Data/plex 0755 1000 1000 - -"
        ];

        virtualisation.oci-containers.containers = {
          dizquetv = {
            image = "vexorian/dizquetv:latest";
            extraOptions = ["--pull=always"];
            ports = ["0.0.0.0:8000:8000"];

            volumes = [
              "/mnt/Data/dizquetv:/home/node/app/.dizquetv"
              "/etc/localtime:/etc/localtime:ro"
            ];
          };
        };
      }

      # prometheus exporters
      (
        {config, ...}: {
          sops.secrets = {
            bazarrApiKey = {
              sopsFile = ../../secrets/arr.yaml;
              key = "bazarr_api_key";
            };
            lidarrApiKey = {
              sopsFile = ../../secrets/arr.yaml;
              key = "lidarr_api_key";
            };
            prowlarrApiKey = {
              sopsFile = ../../secrets/arr.yaml;
              key = "prowlarr_api_key";
            };
            radarrApiKey = {
              sopsFile = ../../secrets/arr.yaml;
              key = "radarr_api_key";
            };
            sonarrApiKey = {
              sopsFile = ../../secrets/arr.yaml;
              key = "sonarr_api_key";
            };
          };

          services.prometheus.exporters = {
            exportarr-bazarr = {
              enable = true;
              apiKeyFile = config.sops.secrets.bazarrApiKey.path;
              port = 9708;
              url = "https://bazarr.${tnet}";
            };

            exportarr-lidarr = {
              enable = true;
              apiKeyFile = config.sops.secrets.lidarrApiKey.path;
              port = 9709;
              url = "https://lidarr.${tnet}";
            };

            exportarr-prowlarr = {
              enable = true;
              apiKeyFile = config.sops.secrets.prowlarrApiKey.path;
              port = 9710;
              url = "https://prowlarr.${tnet}";
            };

            exportarr-radarr = {
              enable = true;
              apiKeyFile = config.sops.secrets.radarrApiKey.path;
              port = 9711;
              url = "https://radarr.${tnet}";
            };

            exportarr-sonarr = {
              enable = true;
              apiKeyFile = config.sops.secrets.sonarrApiKey.path;
              port = 9712;
              url = "https://sonarr.${tnet}";
            };

            smartctl.enable = true;
          };
        }
      )

      # services
      (
        {config, ...}: {
          myBackups.jobs = {
            immich = {
              paths = [
                "${dataDirectory}/immich/library"
                "${dataDirectory}/immich/profile"
                "${dataDirectory}/immich/upload"
                "${dataDirectory}/immich/backups"
              ];
            };

            plex = {
              exclude = ["${dataDirectory}/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases"];
              paths = ["${dataDirectory}/plex"];
            };
          };

          networking.firewall = {
            allowedTCPPorts =
              [6881]
              ++ [
                # Plex (hostNetwork): PMS, Companion, HTTPS
                32400
                8324
                32443
              ];
            allowedUDPPorts = [
              # Plex (hostNetwork): DLNA + GDM auto-discovery
              1900
              32410
              32412
              32413
              32414
            ];
            extraInputRules = ''
              -s ${k3sPodCidr} -p tcp --dport 2049 -j ACCEPT
              -s ${k3sPodCidr} -p udp --dport 2049 -j ACCEPT
            '';
          };

          services = {
            nfs.server = {
              enable = true;
              exports = ''
                /mnt/Data 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,fsid=0) ${k3sPodCidr}(rw,sync,no_subtree_check,no_root_squash,fsid=0)
                /mnt/Media 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,fsid=1) ${k3sPodCidr}(rw,sync,no_subtree_check,no_root_squash,fsid=1)
              '';
            };

            samba = {
              enable = true;
              openFirewall = true;

              settings = {
                global = {
                  security = "user";
                  "map to guest" = "Bad User";

                  # Protocol tuning
                  "server min protocol" = "SMB3";
                  "server max protocol" = "SMB3_11";

                  # Performance options
                  "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=262144 SO_SNDBUF=262144";
                  "use sendfile" = "no"; # Plex compatibility
                  "aio read size" = "1";
                  "aio write size" = "1";
                  "min receivefile size" = "131072"; # Bump slightly from 16K to 128K
                  "max xmit" = "65535"; # Samba's max recommended for best throughput

                  # Locking & latency
                  "strict locking" = "no";
                  "oplocks" = "yes";
                  "level2 oplocks" = "yes";
                };

                Data = {
                  "create mask" = "0755";
                  "directory mask" = "0755";
                  "force group" = "users";
                  "force user" = "aly";
                  "guest ok" = "yes";
                  "read only" = "no";
                  browseable = "yes";
                  comment = "Data @ ${config.networking.hostName}";
                  path = dataDirectory;
                };

                Media = {
                  "create mask" = "0755";
                  "directory mask" = "0755";
                  "force group" = "users";
                  "force user" = "aly";
                  "guest ok" = "yes";
                  "read only" = "no";
                  browseable = "yes";
                  comment = "Media @ ${config.networking.hostName}";
                  path = "/mnt/Media";
                };
              };
            };

            samba-wsdd = {
              enable = true;
              openFirewall = true;
            };

            smartd.enable = true;

            snapper.configs.media = {
              ALLOW_GROUPS = ["users"];
              FSTYPE = "btrfs";
              SUBVOLUME = "/mnt/Media";
              TIMELINE_CLEANUP = true;
              TIMELINE_CREATE = true;
            };

            tuned = {
              enable = true;
              settings.dynamic_tuning = true;
            };
          };
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
