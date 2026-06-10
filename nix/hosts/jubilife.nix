{
  config,
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.jubilife = inputs.nixpkgs.lib.nixosSystem {
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
      amd-cpu
      arr
      auto-upgrade
      b2-mounts
      backups
      btrfs
      caddy
      forgejo-runner
      hw-base
      intel-gpu
      k3s-node
      lanzaboote
      nix-config
      plex
      podman
      prometheus-node
      qbittorrent
      swap
      syncthing
      tailscale
      tautulli
      vps
      zram

      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      config.flake.diskoConfigurations.luks-btrfs-subvolumes
      (
        {
          config,
          lib,
          pkgs,
          ...
        }: let
          dataDirectory = "/mnt/Data";
        in {
          boot = {
            initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" "r8169"];
            kernelModules = ["sg"];
          };

          environment.systemPackages = with pkgs; [
            abcde
            chezmoi
            claude-code
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

          services.udev.extraRules = let
            mkRule = as: lib.concatStringsSep ", " as;
            mkRules = rs: lib.concatStringsSep "\n" rs;
          in
            mkRules [
              (mkRule [
                ''ACTION=="add|change"''
                ''SUBSYSTEM=="block"''
                ''KERNEL=="sd[a-z]"''
                ''ATTR{queue/rotational}=="1"''
                ''RUN+="${pkgs.hdparm}/bin/hdparm -B 90 -S 41 /dev/%k"''
              ])
            ];

          system.stateVersion = "25.11";
          myDisko.installDrive = "/dev/disk/by-id/nvme-PNY_CS2130_1TB_SSD_PNY211821050701050CC";

          myArr.dataDir = "/mnt/Data";
          myAutoUpgrade.dates = "04:15";

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
            role = "agent";
            serverAddr = "https://pastoria:6443";
            zone = "home";
          };

          myPlex.dataDir = "/mnt/Data";

          myQbittorrent.port = 8080;

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
        ];

        virtualisation.oci-containers.containers = {
          # arm = {
          #   autoStart = true;
          #   image = "automaticrippingmachine/automatic-ripping-machine:latest";
          #   ports = ["8181:8080"];

          #   volumes = [
          #     "/mnt/Data/arm/home:/home/arm"
          #     "/mnt/Data/arm/config:/etc/arm/config"
          #   ];

          #   extraOptions = [
          #     # Needed for ARM to work correctly - by default `CAP_SYS_ADMIN` is dropped
          #     # which blocks `mount()` calls within the container
          #     # This is needed in order to `mount /dev/sr0 /mnt/dev/sr0` for ripping, which may be avoidable by
          #     # handling mounts outside of the container, and having `/mnt/dev` bind mounted into the container.
          #     "--privileged"
          #     # Pass the CD/Bluray/DVD drive to the container
          #     "--device=/dev/sr0:/dev/sr0"
          #     "--pull=always"
          #   ];
          # };

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
              url = "https://bazarr.narwhal-snapper.ts.net";
            };

            exportarr-lidarr = {
              enable = true;
              apiKeyFile = config.sops.secrets.lidarrApiKey.path;
              port = 9709;
              url = "https://lidarr.narwhal-snapper.ts.net";
            };

            exportarr-prowlarr = {
              enable = true;
              apiKeyFile = config.sops.secrets.prowlarrApiKey.path;
              port = 9710;
              url = "https://prowlarr.narwhal-snapper.ts.net";
            };

            exportarr-radarr = {
              enable = true;
              apiKeyFile = config.sops.secrets.radarrApiKey.path;
              port = 9711;
              url = "https://radarr.narwhal-snapper.ts.net";
            };

            exportarr-sonarr = {
              enable = true;
              apiKeyFile = config.sops.secrets.sonarrApiKey.path;
              port = 9712;
              url = "https://sonarr.narwhal-snapper.ts.net";
            };

            smartctl.enable = true;
          };
        }
      )

      # services
      (
        {
          config,
          pkgs,
          ...
        }: let
          dataDirectory = "/mnt/Data";
          tnet = "narwhal-snapper.ts.net";
          stop = service: "${pkgs.systemd}/bin/systemctl stop ${service}";
          start = service: "${pkgs.systemd}/bin/systemctl start ${service}";
        in {
          myBackups.jobs = {
            immich = {
              backupCleanupCommand = start "immich-server";
              backupPrepareCommand = stop "immich-server";
              paths = [
                "${config.services.immich.mediaLocation}/library"
                "${config.services.immich.mediaLocation}/profile"
                "${config.services.immich.mediaLocation}/upload"
                "${config.services.immich.mediaLocation}/backups"
              ];
            };

            jellyfin = {
              backupCleanupCommand = start "jellyfin";
              backupPrepareCommand = stop "jellyfin";
              paths = [config.services.jellyfin.dataDir];
            };

            postgresql = {
              backupCleanupCommand = start "postgresql";
              backupPrepareCommand = stop "postgresql";
              paths = [config.services.postgresql.dataDir];
            };
          };

          sops = {
            templates."immich-config.json" = {
              owner = "immich";
              content = ''
                {
                  "oauth": {
                    "enabled": true,
                    "issuerUrl": "https://id.cute.haus",
                    "clientId": "${config.sops.placeholder.immichOauthClientId}",
                    "clientSecret": "${config.sops.placeholder.immichOauthClientSecret}",
                    "scope": "openid email profile",
                    "buttonText": "Sign in with cute.haus",
                    "autoRegister": true,
                    "autoLaunch": false,
                    "mobileOverrideEnabled": false,
                    "mobileRedirectUri": ""
                  }
                }
              '';
            };

            secrets = {
              immichOauthClientId = {
                sopsFile = ../../secrets/immich.yaml;
                key = "oauth/client_id";
                owner = "immich";
              };
              immichOauthClientSecret = {
                sopsFile = ../../secrets/immich.yaml;
                key = "oauth/client_secret";
                owner = "immich";
              };
              photoprismAdminPass = {
                sopsFile = ../../secrets/photoprism.yaml;
                key = "ADMIN_PASSWORD";
              };
            };
          };

          networking.firewall.allowedTCPPorts = [6881];

          services = {
            caddy.virtualHosts = {
              "bazarr.${tnet}".extraConfig = ''
                bind tailscale/bazarr
                encode zstd gzip
                reverse_proxy jubilife:6767
              '';

              "jellyfin.${tnet}".extraConfig = ''
                bind tailscale/jellyfin
                encode zstd gzip
                reverse_proxy jubilife:8096 {
                  flush_interval -1
                }
              '';

              "lidarr.${tnet}".extraConfig = ''
                bind tailscale/lidarr
                encode zstd gzip
                reverse_proxy jubilife:8686
              '';

              "navidrome.${tnet}".extraConfig = ''
                bind tailscale/navidrome
                encode zstd gzip
                reverse_proxy snowpoint:4533
              '';

              "ollama.${tnet}".extraConfig = ''
                bind tailscale/ollama
                encode zstd gzip
                reverse_proxy jubilife:11434
              '';

              "prowlarr.${tnet}".extraConfig = ''
                bind tailscale/prowlarr
                encode zstd gzip
                reverse_proxy jubilife:9696
              '';

              "qbittorrent.${tnet}".extraConfig = ''
                bind tailscale/qbittorrent
                encode zstd gzip
                reverse_proxy jubilife:8080
              '';

              "radarr.${tnet}".extraConfig = ''
                bind tailscale/radarr
                encode zstd gzip
                reverse_proxy jubilife:7878
              '';

              "sonarr.${tnet}".extraConfig = ''
                bind tailscale/sonarr
                encode zstd gzip
                reverse_proxy jubilife:8989
              '';

              "tautulli.${tnet}".extraConfig = ''
                bind tailscale/tautulli
                encode zstd gzip
                reverse_proxy jubilife:8181
              '';
            };

            immich = {
              enable = true;
              host = "0.0.0.0";
              mediaLocation = "${dataDirectory}/immich";
              openFirewall = true;
              port = 2283;
              environment.IMMICH_CONFIG_FILE = config.sops.templates."immich-config.json".path;
            };

            jellyfin = {
              enable = true;
              openFirewall = true;
              dataDir = "${dataDirectory}/jellyfin";
            };

            nfs.server = {
              enable = true;
              exports = ''
                /mnt/Data 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,fsid=0)
                /mnt/Media 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,fsid=1)
              '';
            };

            ollama = {
              enable = true;
              host = "0.0.0.0";

              loadModels = [
                "gemma3:12b"
                "gemma3:4b"
                "nomic-embed-text"
              ];

              openFirewall = true;
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
