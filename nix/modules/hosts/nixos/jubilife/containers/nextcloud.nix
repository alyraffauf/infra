_: {
  flake.nixosModules.jubilife = {
    config,
    inputs,
    pkgs,
    ...
  }: {
    systemd.tmpfiles.rules = [
      "d /mnt/Data/nextcloud/html 0750 33 33 - -"
      "d /mnt/Data/nextcloud/valkey 0750 999 999 - -"
      "d /mnt/Data/postgres 0700 999 999 - -"
    ];

    sops.secrets = {
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

    myNixOs.docker.networks.nextcloud = {
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

    virtualisation.oci-containers.containers = {
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
        image = "valkey/valkey:9-alpine@sha256:de31910896150d5e754a07d57d227cfdde4e258ddd0d1aa4607f2d2f95843715";
        networks = ["nextcloud"];
        cmd = ["valkey-server" "--maxmemory" "256mb" "--maxmemory-policy" "volatile-lru"];
        volumes = ["/mnt/Data/nextcloud/valkey:/data"];
      };

      nextcloud = {
        image = "docker.io/library/nextcloud:34-apache@sha256:368cd1c75bc4a32c2aee8a119cae31bcebff80c374782f404c440c3295726814";
        dependsOn = ["postgres" "nextcloud-valkey"];
        networks = ["nextcloud"];
        environment = {
          APACHE_DISABLE_REWRITE_IP = "1";
          MAIL_DOMAIN = "aly.social";
          MAIL_FROM_ADDRESS = "admin";
          NEXTCLOUD_ADMIN_USER = "alyraffauf";
          NEXTCLOUD_TRUSTED_DOMAINS = "nextcloud.cute.haus";
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
        image = "docker.io/library/nextcloud:34-apache@sha256:368cd1c75bc4a32c2aee8a119cae31bcebff80c374782f404c440c3295726814";
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
      docker-postgres.unitConfig.RequiresMountsFor = ["/mnt/Data"];
      docker-nextcloud-valkey.unitConfig.RequiresMountsFor = ["/mnt/Data"];

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
