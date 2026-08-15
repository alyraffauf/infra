{
  config,
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
    "d /mnt/Data/immich/postgres 0700 root root - -"
    "d /mnt/Data/nextcloud/html 0750 33 33 - -"
    "d /mnt/Data/paperless 0750 1000 1000 - -"
    "d /mnt/Data/paperless/data 0750 1000 1000 - -"
    "d /mnt/Data/paperless/consume 0750 1000 1000 - -"
    "d /mnt/Data/paperless/media 0750 1000 1000 - -"
  ];

  sops.secrets = {
    immichDbPassword = {
      sopsFile = "${inputs.self}/k8s/flux/secrets/immich-env.sops.yaml";
      key = "data/DB_PASSWORD";
    };
    immichConfig = {
      sopsFile = "${inputs.self}/k8s/flux/secrets/immich-config.sops.yaml";
      key = "data/config.json";
    };
  };
  sops.templates = {
    immich-postgres-environment.content = "POSTGRES_PASSWORD=${config.sops.placeholder.immichDbPassword}";
    immich-server-environment.content = "DB_PASSWORD=${config.sops.placeholder.immichDbPassword}";
  };

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

    immich-postgres = {
      image = "ghcr.io/immich-app/postgres:17-vectorchord0.4.3-pgvector0.8.0@sha256:0baf4cde9b54d8d7dc6a6ad8d8c43c3c6b884f82e1c2a023d571414820e39336";
      environment = {
        PGDATA = "/var/lib/postgresql/data/pgdata";
        POSTGRES_DB = "immich";
        POSTGRES_INITDB_ARGS = "--data-checksums";
        POSTGRES_USER = "immich";
      };
      environmentFiles = [config.sops.templates.immich-postgres-environment.path];
      extraOptions = ["--cpus=2" "--memory=3g" "--network=immich" "--pull=always" "--shm-size=128m"];
      volumes = ["/mnt/Data/immich/postgres:/var/lib/postgresql/data"];
    };
    immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:v3.1.0-openvino@sha256:627dfaf9339037be132209784883f7be13c1deb6be799454797bf6f231331f5b";
      environment.MACHINE_LEARNING_CACHE_FOLDER = "/cache";
      extraOptions = ["--cpus=4" "--device=/dev/dri:/dev/dri" "--memory=4g" "--network=immich" "--pull=always"];
      volumes = ["/mnt/Data/immich/ml-cache:/cache"];
    };
    immich-valkey = {
      image = "valkey/valkey:9-alpine@sha256:ee91f7a174ac4d6a6b0685b3a60e321f0a9dbbb691f9b0e285be2ba1d1be8328";
      cmd = ["valkey-server" "--maxmemory" "1gb" "--maxmemory-policy" "volatile-lru"];
      extraOptions = ["--memory=1536m" "--network=immich" "--pull=always"];
    };
    immich = {
      image = "ghcr.io/immich-app/immich-server:v3.1.0@sha256:b434cb9287eea1471c9974845914d4dd328c9c2d652e446ed4930f99944f0ceb";
      environment = {
        DB_DATABASE_NAME = "immich";
        DB_HOSTNAME = "immich-postgres";
        DB_PORT = "5432";
        DB_USERNAME = "immich";
        IMMICH_CONFIG_FILE = "/etc/immich/config.json";
        IMMICH_MACHINE_LEARNING_URL = "http://immich-machine-learning:3003";
        REDIS_DBINDEX = "0";
        REDIS_HOSTNAME = "immich-valkey";
        TZ = "America/New_York";
      };
      environmentFiles = [config.sops.templates.immich-server-environment.path];
      extraOptions = ["--cpus=4" "--memory=4g" "--network=immich" "--pull=always" "--ulimit=nofile=8192:8192"];
      ports = ["10.254.0.1:2283:2283"];
      volumes = ["/mnt/Data/immich:/data" "${config.sops.secrets.immichConfig.path}:/etc/immich/config.json:ro"];
    };
  };

  systemd.services = {
    docker-network-immich = {
      after = ["docker.service"];
      requires = ["docker.service"];
      before = ["docker-immich-postgres.service" "docker-immich-machine-learning.service" "docker-immich-valkey.service" "docker-immich.service"];
      requiredBy = ["docker-immich-postgres.service" "docker-immich-machine-learning.service" "docker-immich-valkey.service" "docker-immich.service"];
      path = [pkgs.docker];
      script = "docker network inspect immich >/dev/null 2>&1 || docker network create immich";
      serviceConfig.Type = "oneshot";
    };
    docker-immich.enable = false;
    docker-immich-machine-learning.enable = false;
    docker-immich-postgres.enable = false;
    docker-immich-valkey.enable = false;
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
