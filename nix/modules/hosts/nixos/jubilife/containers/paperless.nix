_: {
  flake.nixosModules.jubilife = {
    config,
    inputs,
    pkgs,
    ...
  }: {
    sops.secrets = {
      paperlessAdminPassword = {
        sopsFile = "${inputs.self}/secrets/paperless.yaml";
        key = "PAPERLESS_ADMIN_PASSWORD";
        restartUnits = ["docker-paperless.service"];
      };
      paperlessDatabasePassword = {
        sopsFile = "${inputs.self}/secrets/paperless.yaml";
        key = "PAPERLESS_DBPASS";
      };
      paperlessSecretKey = {
        sopsFile = "${inputs.self}/secrets/paperless.yaml";
        key = "PAPERLESS_SECRET_KEY";
        restartUnits = ["docker-paperless.service"];
      };
      paperlessSocialAccountProviders = {
        sopsFile = "${inputs.self}/secrets/paperless.yaml";
        key = "PAPERLESS_SOCIALACCOUNT_PROVIDERS";
        restartUnits = ["docker-paperless.service"];
      };
    };

    sops.templates = {
      paperless-database-environment.content = ''
        PAPERLESS_DBPASS=${config.sops.placeholder.paperlessDatabasePassword}
      '';
      paperless-environment.content = ''
        PAPERLESS_ADMIN_PASSWORD=${config.sops.placeholder.paperlessAdminPassword}
        PAPERLESS_DBPASS=${config.sops.placeholder.paperlessDatabasePassword}
        PAPERLESS_SECRET_KEY=${config.sops.placeholder.paperlessSecretKey}
        PAPERLESS_SOCIALACCOUNT_PROVIDERS=${config.sops.placeholder.paperlessSocialAccountProviders}
      '';
    };

    myNixOs.docker.networks.paperless.containers = [
      "postgres"
      "paperless-valkey"
      "tika"
      "gotenberg"
      "paperless"
    ];

    virtualisation.oci-containers.containers = {
      paperless-valkey = {
        image = "valkey/valkey:9-alpine@sha256:ee91f7a174ac4d6a6b0685b3a60e321f0a9dbbb691f9b0e285be2ba1d1be8328";
        networks = ["paperless"];
        cmd = ["valkey-server" "--maxmemory" "1gb" "--maxmemory-policy" "volatile-lru"];
        extraOptions = ["--tmpfs=/data:rw,noexec,nosuid,size=1g"];
      };

      tika = {
        image = "apache/tika:3.3.1.0-full@sha256:d8e6ed96260ad89307a93195a1b856102987a818ac648502f8efbaf313d32470";
        networks = ["paperless"];
        extraOptions = ["--memory=4g"];
        ports = ["10.254.0.1:9998:9998"];
      };

      gotenberg = {
        image = "gotenberg/gotenberg:8@sha256:87c16b9f364279d321bc9772d31fa58aa6abe036423c270698bd636c3a8e9466";
        networks = ["paperless"];
        extraOptions = ["--memory=1g"];
        ports = ["10.254.0.1:3000:3000"];
      };

      paperless = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:latest@sha256:65a4cabf0169ea7fbd90ab7bb28ba3f8b5909613635acda1a03ad606f34b456b";
        dependsOn = ["postgres" "paperless-valkey" "tika" "gotenberg"];
        networks = ["paperless"];
        environment = {
          PAPERLESS_ACCOUNT_DEFAULT_GROUP = "users";
          PAPERLESS_ACCOUNT_DEFAULT_HTTP_PROTOCOL = "https";
          PAPERLESS_ADMIN_MAIL = "alyraffauf@fastmail.com";
          PAPERLESS_ADMIN_USER = "alyraffauf";
          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
          PAPERLESS_CONSUMER_DELETE = "true";
          PAPERLESS_CONSUMPTION_DIR = "/paperless/consume";
          PAPERLESS_DATA_DIR = "/paperless/data";
          PAPERLESS_DBHOST = "postgres";
          PAPERLESS_DBNAME = "paperless";
          PAPERLESS_DBPORT = "5432";
          PAPERLESS_DBUSER = "paperless";
          PAPERLESS_MEDIA_ROOT = "/paperless/media";
          PAPERLESS_OCR_LANGUAGE = "eng";
          PAPERLESS_OCR_PAGES = "2";
          PAPERLESS_PROXY_SSL_HEADER = ''["HTTP_X_FORWARDED_PROTO", "https"]'';
          PAPERLESS_REDIS = "redis://paperless-valkey:6379/0";
          PAPERLESS_SOCIAL_AUTO_SIGNUP = "True";
          PAPERLESS_TASK_WORKERS = "1";
          PAPERLESS_TIKA_ENABLED = "1";
          PAPERLESS_TIKA_ENDPOINT = "http://tika:9998";
          PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://gotenberg:3000";
          PAPERLESS_TIME_ZONE = "America/New_York";
          PAPERLESS_URL = "https://paperless.cute.haus";
          PAPERLESS_USE_X_FORWARD_HOST = "true";
          PAPERLESS_USE_X_FORWARD_PORT = "true";
          USERMAP_GID = "1000";
          USERMAP_UID = "1000";
        };
        environmentFiles = [config.sops.templates.paperless-environment.path];
        extraOptions = ["--memory=8g"];
        ports = ["10.254.0.1:8001:8000"];
        volumes = [
          "/mnt/Data/paperless/data:/paperless/data"
          "/mnt/Data/paperless/consume:/paperless/consume"
          "/mnt/Data/paperless/media:/paperless/media"
        ];
      };
    };

    systemd.services = {
      docker-connect-postgres-paperless = {
        description = "Connect PostgreSQL to the Paperless Docker network";
        after = ["docker-network-paperless.service" "docker-postgres.service"];
        requires = ["docker-network-paperless.service" "docker-postgres.service"];
        before = ["postgres-bootstrap-paperless.service"];
        wantedBy = ["multi-user.target"];
        path = [pkgs.docker];
        script = "docker network connect paperless postgres 2>/dev/null || true";
        serviceConfig.Type = "oneshot";
      };

      postgres-bootstrap-paperless = {
        description = "Create the local Paperless PostgreSQL role and database";
        after = ["docker-connect-postgres-paperless.service"];
        requires = ["docker-connect-postgres-paperless.service"];
        before = ["docker-paperless.service"];
        wantedBy = ["multi-user.target"];
        path = [pkgs.docker];
        script = ''
          set -eu
          source ${config.sops.templates.paperless-database-environment.path}

          docker exec -i postgres psql \
            --username postgres \
            --dbname postgres \
            --set ON_ERROR_STOP=1 \
            --set paperless_database_password="$PAPERLESS_DBPASS" <<'SQL'
          SELECT format('CREATE ROLE paperless LOGIN PASSWORD %L', :'paperless_database_password')
          WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'paperless')
          \gexec
          ALTER ROLE paperless LOGIN PASSWORD :'paperless_database_password';
          SELECT 'CREATE DATABASE paperless OWNER paperless'
          WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'paperless')
          \gexec
          SQL
        '';
        serviceConfig.Type = "oneshot";
      };

      docker-paperless.unitConfig = {
        ConditionPathExists = "/mnt/Data/paperless/.local-postgres-ready";
        RequiresMountsFor = ["/mnt/Data"];
      };
    };
  };
}
