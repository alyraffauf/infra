_: {
  flake.nixosModules.jubilife = {
    config,
    inputs,
    pkgs,
    ...
  }: {
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
      "d /mnt/Data/immich/postgres 0700 999 999 - -"
      "d /mnt/Data/nextcloud/html 0750 33 33 - -"
      "d /mnt/Data/nextcloud/valkey 0750 999 999 - -"
      "d /mnt/Data/postgres 0700 999 999 - -"
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

      immichConfigBase64 = {
        sopsFile = "${inputs.self}/k8s/flux/secrets/immich-config.sops.yaml";
        key = "data/config.json";
        restartUnits = [
          "docker-immich.service"
        ];
      };

      postgresPassword.sopsFile = "${inputs.self}/secrets/postgres.yaml";

      nextcloudAdminPassword = {
        sopsFile = "${inputs.self}/k8s/flux/secrets/nextcloud-env.sops.yaml";
        key = "data/NEXTCLOUD_ADMIN_PASSWORD";
        restartUnits = ["docker-nextcloud.service"];
      };

      nextcloudPostgresPassword = {
        sopsFile = "${inputs.self}/k8s/flux/secrets/nextcloud-env.sops.yaml";
        key = "data/POSTGRES_PASSWORD";
      };

      nextcloudSmtpPassword = {
        sopsFile = "${inputs.self}/k8s/flux/secrets/nextcloud-env.sops.yaml";
        key = "data/SMTP_PASSWORD";
        restartUnits = ["docker-nextcloud.service"];
      };

      nextcloudObjectStoreKey = {
        sopsFile = "${inputs.self}/k8s/flux/secrets/nextcloud-garage-env.sops.yaml";
        key = "stringData/OBJECTSTORE_S3_KEY";
        restartUnits = ["docker-nextcloud.service"];
      };

      nextcloudObjectStoreSecret = {
        sopsFile = "${inputs.self}/k8s/flux/secrets/nextcloud-garage-env.sops.yaml";
        key = "stringData/OBJECTSTORE_S3_SECRET";
        restartUnits = ["docker-nextcloud.service"];
      };
    };

    sops.templates = {
      immich-postgres-environment.content = "POSTGRES_PASSWORD=${config.sops.placeholder.immichDbPassword}";
      immich-server-environment.content = "DB_PASSWORD=${config.sops.placeholder.immichDbPassword}";
      postgres-environment.content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder.postgresPassword}
        NEXTCLOUD_POSTGRES_PASSWORD=${config.sops.placeholder.nextcloudPostgresPassword}
      '';
      nextcloud-environment.content = ''
        NEXTCLOUD_ADMIN_PASSWORD=${config.sops.placeholder.nextcloudAdminPassword}
        POSTGRES_PASSWORD=${config.sops.placeholder.nextcloudPostgresPassword}
        SMTP_PASSWORD=${config.sops.placeholder.nextcloudSmtpPassword}
        OBJECTSTORE_S3_KEY=${config.sops.placeholder.nextcloudObjectStoreKey}
        OBJECTSTORE_S3_SECRET=${config.sops.placeholder.nextcloudObjectStoreSecret}
      '';
    };

    myNixOs.docker.networks = {
      immich.containers = [
        "immich-postgres"
        "immich-machine-learning"
        "immich-valkey"
        "immich"
      ];

      nextcloud = {
        containers = [
          "postgres"
          "nextcloud-valkey"
          "nextcloud"
          "nextcloud-cron"
        ];
        subnet = "172.19.0.0/16";
        bridgeInterface = "nextcloud0";
        allowedTCPPorts = [3900];
      };
    };

    virtualisation.oci-containers.containers = {
      dizquetv = {
        image = "vexorian/dizquetv:latest@sha256:98a7bc11dc5d16732c06c779ac7fd843dc4254853203f2d9dd9293b099743ca1";
        ports = ["0.0.0.0:8000:8000"];
        volumes = [
          "/mnt/Data/dizquetv:/home/node/app/.dizquetv"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };

      plex = {
        image = "docker.io/plexinc/pms-docker:1.43.3.10861-07dfddaeb@sha256:5bc1d13f48da6366f46aaf2a3ce1a6292897eadc1f8efcbbd7321d30e94f2ed4";
        devices = ["/dev/dri:/dev/dri"];

        environment = {
          ADVERTISE_IP = "https://plex.cute.haus:443";
          PLEX_GID = "1000";
          PLEX_UID = "1000";
          TZ = "America/New_York";
        };

        extraOptions = [
          "--group-add=44"
          "--memory=4g"
          "--network=host"
        ];

        volumes = [
          "/mnt/Data/plex:/config"
          "/mnt/Media:/mnt/Media:ro"
          "/etc/localtime:/etc/localtime:ro"
          "/mnt/Backblaze:/mnt/Backblaze:ro,rslave"
          "${inputs.audnexus}:/config/Library/Application Support/Plex Media Server/Plug-ins/Audnexus.bundle:ro"
          "${inputs.hama}:/config/Library/Application Support/Plex Media Server/Plug-ins/Hama.bundle:ro"
          "${inputs.absolute}/Scanners:/config/Library/Application Support/Plex Media Server/Scanners:ro"
        ];
      };

      slingshot = {
        image = "ghcr.io/alyraffauf/slingshot:latest@sha256:6e3a2860f0c4aa98e6f95f9ff6a7d9eb61266f2272e3eaeb6de32ba221b20e38";

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
          "--tmpfs=/cache:rw,size=8g,uid=65532,gid=65532"
          "--ulimit=nofile=8192:8192"
        ];

        ports = ["10.254.0.1:8765:8080"];
      };

      immich-postgres = {
        image = "ghcr.io/immich-app/postgres:17-vectorchord0.4.3-pgvector0.8.0@sha256:0baf4cde9b54d8d7dc6a6ad8d8c43c3c6b884f82e1c2a023d571414820e39336";
        networks = ["immich"];

        environment = {
          PGDATA = "/var/lib/postgresql/data/pgdata";
          POSTGRES_DB = "immich";
          POSTGRES_INITDB_ARGS = "--data-checksums";
          POSTGRES_USER = "immich";
        };

        environmentFiles = [config.sops.templates.immich-postgres-environment.path];

        extraOptions = [
          "--memory=3g"
          "--shm-size=128m"
        ];

        volumes = ["/mnt/Data/immich/postgres:/var/lib/postgresql/data"];
      };

      immich-machine-learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:v3.1.0-openvino@sha256:627dfaf9339037be132209784883f7be13c1deb6be799454797bf6f231331f5b";
        devices = ["/dev/dri:/dev/dri"];
        networks = ["immich"];
        environment.MACHINE_LEARNING_CACHE_FOLDER = "/cache";
        extraOptions = [
          "--memory=4g"
        ];
        volumes = ["/mnt/Data/immich/ml-cache:/cache"];
      };

      immich-valkey = {
        image = "valkey/valkey:9-alpine@sha256:ee91f7a174ac4d6a6b0685b3a60e321f0a9dbbb691f9b0e285be2ba1d1be8328";
        networks = ["immich"];
        cmd = ["valkey-server" "--maxmemory" "1gb" "--maxmemory-policy" "volatile-lru"];
      };

      immich = {
        image = "ghcr.io/immich-app/immich-server:v3.1.0@sha256:b434cb9287eea1471c9974845914d4dd328c9c2d652e446ed4930f99944f0ceb";
        dependsOn = [
          "immich-postgres"
          "immich-machine-learning"
          "immich-valkey"
        ];
        networks = ["immich"];
        environment = {
          DB_DATABASE_NAME = "immich";
          DB_HOSTNAME = "immich-postgres";
          DB_PORT = "5432";
          DB_USERNAME = "immich";
          IMMICH_CONFIG_FILE = "/etc/immich/config.json";
          IMMICH_MACHINE_LEARNING_URL = "http://immich-machine-learning:3003";
          REDIS_DBINDEX = "4";
          REDIS_HOSTNAME = "immich-valkey";
          TZ = "America/New_York";
        };
        environmentFiles = [config.sops.templates.immich-server-environment.path];
        extraOptions = [
          "--memory=4g"
          "--ulimit=nofile=8192:8192"
        ];
        ports = ["10.254.0.1:2283:2283"];
        volumes = [
          "/mnt/Data/immich:/data"
          "/run/immich/config.json:/etc/immich/config.json:ro"
        ];
      };

      postgres = {
        image = "docker.io/library/postgres:18.6@sha256:cd78ca58eb75f929698e117a589488ccb2bd45107247fe02400b50ff6c418324";
        networks = ["nextcloud"];
        environment = {
          POSTGRES_DB = "postgres";
          POSTGRES_USER = "postgres";
        };
        environmentFiles = [config.sops.templates.postgres-environment.path];
        volumes = [
          "/mnt/Data/postgres:/var/lib/postgresql"
          "${pkgs.writeShellScript "postgres-init-nextcloud" ''
            set -eu
            psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \\
              --set=nextcloud_postgres_password="$NEXTCLOUD_POSTGRES_PASSWORD" <<'SQL'
            CREATE ROLE nextcloud LOGIN PASSWORD :'nextcloud_postgres_password';
            CREATE DATABASE nextcloud OWNER nextcloud;
            SQL
          ''}:/docker-entrypoint-initdb.d/10-nextcloud.sh:ro"
        ];
      };

      nextcloud-valkey = {
        image = "valkey/valkey:9-alpine@sha256:ee91f7a174ac4d6a6b0685b3a60e321f0a9dbbb691f9b0e285be2ba1d1be8328";
        networks = ["nextcloud"];
        cmd = ["valkey-server" "--maxmemory" "256mb" "--maxmemory-policy" "volatile-lru"];
        volumes = ["/mnt/Data/nextcloud/valkey:/data"];
      };

      nextcloud = {
        image = "docker.io/library/nextcloud:34-apache@sha256:6eb64bc58acd8dd751415f15c470d397fe922cefbd154e48480f5fcd9ce3a8e5";
        dependsOn = [
          "postgres"
          "nextcloud-valkey"
        ];
        networks = ["nextcloud"];
        environment = {
          APACHE_DISABLE_REWRITE_IP = "1";
          MAIL_DOMAIN = "aly.social";
          MAIL_FROM_ADDRESS = "admin";
          OBJECTSTORE_S3_AUTOCREATE = "false";
          OBJECTSTORE_S3_BUCKET = "aly-nextcloud";
          OBJECTSTORE_S3_HOST = "host.docker.internal";
          OBJECTSTORE_S3_PORT = "3900";
          OBJECTSTORE_S3_REGION = "garage";
          OBJECTSTORE_S3_SSL = "false";
          OBJECTSTORE_S3_USEPATH_STYLE = "true";
          OVERWRITECLIURL = "https://nextcloud.cute.haus";
          OVERWRITEHOST = "nextcloud.cute.haus";
          OVERWRITEPROTOCOL = "https";
          PHP_MEMORY_LIMIT = "512M";
          PHP_UPLOAD_LIMIT = "10G";
          POSTGRES_DB = "nextcloud";
          POSTGRES_HOST = "postgres";
          POSTGRES_USER = "nextcloud";
          REDIS_HOST = "nextcloud-valkey";
          REDIS_HOST_PORT = "6379";
          SMTP_AUTHTYPE = "LOGIN";
          SMTP_HOST = "smtp.resend.com";
          SMTP_NAME = "resend";
          SMTP_PORT = "465";
          SMTP_SECURE = "ssl";
          TRUSTED_PROXIES = "10.42.0.0/16";
          NEXTCLOUD_ADMIN_USER = "alyraffauf";
          NEXTCLOUD_TRUSTED_DOMAINS = "nextcloud.cute.haus";
        };
        environmentFiles = [config.sops.templates.nextcloud-environment.path];
        extraOptions = [
          "--add-host=host.docker.internal:172.19.0.1"
          "--memory=4g"
        ];
        ports = ["10.254.0.1:8081:80"];
        volumes = ["/mnt/Data/nextcloud/html:/var/www/html"];
      };

      nextcloud-cron = {
        image = "docker.io/library/nextcloud:34-apache@sha256:6eb64bc58acd8dd751415f15c470d397fe922cefbd154e48480f5fcd9ce3a8e5";
        dependsOn = ["nextcloud"];
        networks = ["nextcloud"];
        cmd = ["/bin/sh" "-c" "while true; do php -f /var/www/html/cron.php || true; sleep 60; done"];
        environment = {
          POSTGRES_DB = "nextcloud";
          POSTGRES_HOST = "postgres";
          POSTGRES_USER = "nextcloud";
          REDIS_HOST = "nextcloud-valkey";
          REDIS_HOST_PORT = "6379";
        };
        environmentFiles = [config.sops.templates.nextcloud-environment.path];
        extraOptions = [
          "--add-host=host.docker.internal:172.19.0.1"
          "--user=33:33"
        ];
        volumes = ["/mnt/Data/nextcloud/html:/var/www/html"];
      };
    };

    systemd.services = {
      docker-dizquetv.unitConfig.RequiresMountsFor = ["/mnt/Data"];

      docker-plex.unitConfig.RequiresMountsFor = [
        "/mnt/Data"
        "/mnt/Media"
      ];

      docker-immich = {
        preStart = ''
          ${pkgs.coreutils}/bin/base64 --decode \
            < "${config.sops.secrets.immichConfigBase64.path}" \
            > "$RUNTIME_DIRECTORY/config.json"
        '';
        serviceConfig = {
          RuntimeDirectory = "immich";
          RuntimeDirectoryMode = "0700";
        };
        unitConfig.RequiresMountsFor = ["/mnt/Data"];
      };

      docker-immich-machine-learning.unitConfig.RequiresMountsFor = ["/mnt/Data"];
      docker-immich-postgres.unitConfig.RequiresMountsFor = ["/mnt/Data"];

      docker-postgres.unitConfig.RequiresMountsFor = ["/mnt/Data"];
      docker-nextcloud-valkey.unitConfig.RequiresMountsFor = ["/mnt/Data"];

      # The migration creates this only after pg_dump has been restored locally.
      docker-nextcloud = {
        preStart = ''
          config_file=/mnt/Data/nextcloud/html/config/config.php

          if ${pkgs.gnugrep}/bin/grep -Fq "pg-shared-rw.cnpg-system.svc" "$config_file"; then
            ${pkgs.gnused}/bin/sed -i \
              -e "s/pg-shared-rw\.cnpg-system\.svc/postgres/" \
              -e "s/valkey\.nextcloud\.svc/nextcloud-valkey/" \
              "$config_file"
          elif ! ${pkgs.gnugrep}/bin/grep -Fq "'dbhost' => 'postgres'" "$config_file"; then
            echo "Nextcloud database host is neither the cluster nor local PostgreSQL" >&2
            exit 1
          fi

          ${pkgs.gnused}/bin/sed -i \
            "s/10\\.254\\.0\\.1/host.docker.internal/g" \
            "$config_file"
        '';
        unitConfig = {
          ConditionPathExists = "/mnt/Data/nextcloud/.local-postgres-ready";
          RequiresMountsFor = ["/mnt/Data"];
        };
      };

      docker-nextcloud-cron.unitConfig = {
        ConditionPathExists = "/mnt/Data/nextcloud/.local-postgres-ready";
        RequiresMountsFor = ["/mnt/Data"];
      };
    };
  };
}
