{
  inputs,
  self,
  ...
}: let
  tnet = "narwhal-snapper.ts.net";
  dataDirectory = "/mnt/Data";
  k3sPodCidr = "10.42.0.0/16";
in [
  self.nixosModules.myHw
  self.nixosModules.myNixOs
  self.nixosModules.myDisko

  {
    myHw = {
      amd.cpu.enable = true;
      intel.gpu.enable = true;
    };

    myNixOs = {
      profile = {
        arr.enable = true;
        b2Mounts.enable = true;
        backups.enable = true;
        base.enable = true;
        btrfs.enable = true;
        k3s.enable = true;
        localeEnUs.enable = true;
        swap.enable = true;
        vps.enable = true;
        wireguardK3s.enable = true;
      };

      program = {
        lanzaboote.enable = true;
        docker.enable = true;
      };

      service = {
        alloy.enable = true;
        caddy.enable = true;
        fail2ban.enable = true;
        prometheusNode.enable = true;
        qbittorrent.enable = true;
        syncthing.enable = true;
        tailscale.enable = true;
        tautulli.enable = true;
      };

      users.aly.enable = true;
    };

    myDisko = {
      profile.luksBtrfsSubvolumes.enable = true;
    };
  }

  inputs.disko.nixosModules.disko
  inputs.sops-nix.nixosModules.sops
  ./containers.nix
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
      system.autoUpgrade.dates = "04:15";

      myDisko = {
        installDrive = "/dev/disk/by-id/nvme-PNY_CS2130_1TB_SSD_PNY211821050701050CC";
      };

      myNixOs = {
        profile = {
          arr.dataDir = "/mnt/Data";

          b2Mounts = {
            cacheDir = "/mnt/Data/.rclone-cache";
            audioCacheSize = "50G";
            audioReadAhead = "3G";
            videoCacheSize = "300G";
            videoReadAhead = "5G";
          };

          k3s = {
            role = "server";
            clusterInit = true;
            transportInterface = "wg-k3s";
            nodeIP = "10.254.0.1";
            zone = "home";
          };
        };

        service.syncthing = {
          certFile = config.sops.secrets.syncthingCert.path;
          keyFile = config.sops.secrets.syncthingKey.path;
          romsPath = "${dataDirectory}/syncthing/ROMs";
          syncROMs = true;
          user = "aly";
        };

        users.aly.password = "$6$JTk2qi27OpA2fOAY$ZgTDg0wbmbwHUD..0xT4xYX.AR5hWQFCMVmn8G88yi3IAY7015AupovTpfy0arkI7nl/IDu5L09bzLKeXGvJC1";
      };

      sops.secrets = {
        garageNextcloudAccessKey = {
          sopsFile = "${self}/secrets/garage.yaml";
          key = "nextcloud_access_key";
          owner = "garage";
          group = "garage";
        };
        garageNextcloudSecretKey = {
          sopsFile = "${self}/secrets/garage.yaml";
          key = "nextcloud_secret_key";
          owner = "garage";
          group = "garage";
        };
        garageRpcSecret = {
          sopsFile = "${self}/secrets/garage.yaml";
          key = "rpc_secret";
          owner = "garage";
          group = "garage";
        };
        syncthingCert = {
          sopsFile = "${self}/secrets/syncthing.yaml";
          key = "jubilife_cert";
        };
        syncthingKey = {
          sopsFile = "${self}/secrets/syncthing.yaml";
          key = "jubilife_key";
        };
      };

      sops.templates = {
        garage-config = {
          owner = "garage";
          group = "garage";
          mode = "0400";
          content = ''
            metadata_dir = "${dataDirectory}/garage/meta"
            data_dir = "${dataDirectory}/garage/data"
            db_engine = "sqlite"
            replication_factor = 1
            rpc_bind_addr = "[::]:3901"
            rpc_public_addr = "10.254.0.1:3901"
            rpc_secret = "${config.sops.placeholder.garageRpcSecret}"

            [s3_api]
            api_bind_addr = "10.254.0.1:3900"
            s3_region = "garage"
          '';
        };

        garage-environment = {
          owner = "garage";
          group = "garage";
          mode = "0400";
          content = ''
            GARAGE_CONFIG_FILE=${config.sops.templates.garage-config.path}
            GARAGE_DEFAULT_ACCESS_KEY=${config.sops.placeholder.garageNextcloudAccessKey}
            GARAGE_DEFAULT_SECRET_KEY=${config.sops.placeholder.garageNextcloudSecretKey}
            GARAGE_DEFAULT_BUCKET=aly-nextcloud
          '';
        };
      };

      users = {
        groups.garage = {};
        users.garage = {
          isSystemUser = true;
          group = "garage";
        };
      };

      services.garage = {
        enable = true;
        package = pkgs.garage_2;
        environmentFile = config.sops.templates.garage-environment.path;
        settings = {
          metadata_dir = "${dataDirectory}/garage/meta";
          data_dir = "${dataDirectory}/garage/data";
        };
      };

      systemd.services.garage = {
        after = ["mnt-Data.mount"];
        requires = ["mnt-Data.mount"];
        serviceConfig = {
          DynamicUser = false;
          User = "garage";
          Group = "garage";
        };
      };
    }
  )

  # prometheus exporters
  (
    {config, ...}: {
      sops.secrets = {
        bazarrApiKey = {
          sopsFile = "${self}/secrets/arr.yaml";
          key = "bazarr_api_key";
        };
        lidarrApiKey = {
          sopsFile = "${self}/secrets/arr.yaml";
          key = "lidarr_api_key";
        };
        prowlarrApiKey = {
          sopsFile = "${self}/secrets/arr.yaml";
          key = "prowlarr_api_key";
        };
        radarrApiKey = {
          sopsFile = "${self}/secrets/arr.yaml";
          key = "radarr_api_key";
        };
        sonarrApiKey = {
          sopsFile = "${self}/secrets/arr.yaml";
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
      myNixOs = {
        profile.backups.jobs = {
          immich = {
            paths = [
              "${dataDirectory}/immich/library"
              "${dataDirectory}/immich/profile"
              "${dataDirectory}/immich/upload"
              "${dataDirectory}/immich/backups"
            ];
          };

          garage.paths = ["${dataDirectory}/garage"];
          nextcloud.paths = ["${dataDirectory}/nextcloud/html"];
          paperless.paths = ["${dataDirectory}/paperless"];

          plex = {
            exclude = ["${dataDirectory}/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases"];
            paths = ["${dataDirectory}/plex"];
          };
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
          -s ${k3sPodCidr} -p tcp --dport 3900 -j ACCEPT
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
]
