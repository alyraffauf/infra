{
  inputs,
  lib,
  pkgs,
  ...
}: let
  plexPlugins = {
    bundles = [
      {
        name = "Audnexus.bundle";
        path = builtins.path {
          name = "Audnexus.bundle";
          path = inputs.audnexus;
        };
      }
      {
        name = "Hama.bundle";
        path = builtins.path {
          name = "Hama.bundle";
          path = inputs.hama;
        };
      }
    ];
    scanners = [
      {
        path = builtins.path {
          name = "Absolute-Series-Scanner";
          path = inputs.absolute;
        };
      }
    ];
  };

  plexBundleSetup =
    lib.concatMapStringsSep "\n" (bundle: ''
      rm --force --recursive "$PLUGINS/${bundle.name}"
      cp --archive "${bundle.path}" "$PLUGINS/${bundle.name}"
    '')
    plexPlugins.bundles;

  plexScannerSetup =
    lib.concatMapStringsSep "\n" (scanner: ''
      cp --archive "${scanner.path}/Scanners/." "$SCANNERS/"
    '')
    plexPlugins.scanners;
in {
  myNixOs.profile.backups.jobs.dizquetv.paths = ["/mnt/Data/dizquetv"];

  systemd.tmpfiles.rules = [
    "z /mnt/Data 0755 root root - -"
    "d /mnt/Data/dizquetv 0755 root root"
    "d /mnt/Data/arm/home 0755 1000 1000 - -"
    "d /mnt/Data/arm/config 0755 1000 1000 - -"
    "d /mnt/Data/arm 0755 1000 1000 - -"
    "d /mnt/Data/jellyfin 0700 1000 1000 - -"
    "d /mnt/Data/plex 0755 1000 1000 - -"
    "d /mnt/Data/garage 0750 garage garage - -"
    "d /mnt/Data/garage/meta 0700 garage garage - -"
    "d /mnt/Data/garage/data 0700 garage garage - -"
    "d /mnt/Data/immich/ml-cache 0755 root root - -"
    "d /mnt/Data/nextcloud/html 0750 33 33 - -"
    "d /mnt/Data/paperless 0750 1000 1000 - -"
    "d /mnt/Data/paperless/data 0750 1000 1000 - -"
    "d /mnt/Data/paperless/consume 0750 1000 1000 - -"
    "d /mnt/Data/paperless/media 0750 1000 1000 - -"
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

    plex = {
      image = "docker.io/plexinc/pms-docker:1.43.3.10861-07dfddaeb@sha256:5bc1d13f48da6366f46aaf2a3ce1a6292897eadc1f8efcbbd7321d30e94f2ed4";
      environment = {
        ADVERTISE_IP = "https://plex.cute.haus:443";
        PLEX_GID = "1000";
        PLEX_UID = "1000";
        TZ = "America/New_York";
      };
      extraOptions = [
        "--cpus=4"
        "--device=/dev/dri:/dev/dri"
        "--group-add=44"
        "--memory=4g"
        "--network=host"
        "--pull=always"
      ];
      volumes = [
        "/mnt/Data/plex:/config"
        "/mnt/Media:/mnt/Media:ro"
        "/etc/localtime:/etc/localtime:ro"
        "/mnt/Backblaze:/mnt/Backblaze:ro,rslave"
      ];
    };

    slingshot = {
      image = "ghcr.io/alyraffauf/slingshot:latest@sha256:24d0777f1beedb946c4b2a06410a55cea75ff883430cc7629a18336207f212f7";
      environment = {
        SLINGSHOT_CACHE_DIR = "/cache";
        SLINGSHOT_IDENTITY_CACHE_DISK_DB = "2";
        SLINGSHOT_IDENTITY_CACHE_MEMORY_MB = "64";
        SLINGSHOT_JETSTREAM = "wss://jetstream1.us-east.bsky.network/subscribe";
        SLINGSHOT_RECORD_CACHE_DISK_DB = "4";
        SLINGSHOT_RECORD_CACHE_MEMORY_MB = "256";
      };
      extraOptions = [
        "--cpus=2"
        "--memory=2g"
        "--pull=always"
        "--tmpfs=/cache:rw,size=8g,uid=65532,gid=65532"
        "--ulimit=nofile=8192:8192"
      ];
      ports = ["10.254.0.1:8765:8080"];
    };
  };

  systemd.services.plex-plugins = {
    description = "Install Plex plugins and scanners from flake inputs";
    before = ["docker-plex.service"];
    requiredBy = ["docker-plex.service"];
    path = [pkgs.coreutils];
    script = ''
      set -euo pipefail

      PMS="/mnt/Data/plex/Library/Application Support/Plex Media Server"
      PLUGINS="$PMS/Plug-ins"
      SCANNERS="$PMS/Scanners"

      mkdir --parents "$PLUGINS" "$SCANNERS"

      ${plexBundleSetup}
      ${plexScannerSetup}

      chown --recursive 1000:1000 "$PLUGINS" "$SCANNERS"
    '';
  };

  systemd.services.docker-plex = {
    after = ["mnt-Data.mount" "mnt-Media.mount"];
    requires = ["mnt-Data.mount" "mnt-Media.mount"];
  };
}
