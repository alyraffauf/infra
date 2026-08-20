_: {
  flake.nixosModules.jubilife = {
    config,
    inputs,
    pkgs,
    ...
  }: {
    systemd.tmpfiles.rules = [
      "d /mnt/Data/immich/ml-cache 0755 root root - -"
      "d /mnt/Data/immich/postgres 0700 999 999 - -"
    ];

    sops.secrets = {
      immichDbPassword = {
        sopsFile = "${inputs.self}/k8s/flux/secrets/immich-env.sops.yaml";
        key = "data/DB_PASSWORD";
      };
      immichConfigBase64 = {
        sopsFile = "${inputs.self}/k8s/flux/secrets/immich-config.sops.yaml";
        key = "data/config.json";
        restartUnits = ["docker-immich.service"];
      };
    };

    sops.templates = {
      immich-postgres-environment.content = "POSTGRES_PASSWORD=${config.sops.placeholder.immichDbPassword}";
      immich-server-environment.content = "DB_PASSWORD=${config.sops.placeholder.immichDbPassword}";
    };

    myNixOs.docker.networks.immich.containers = [
      "immich-postgres"
      "immich-machine-learning"
      "immich-valkey"
      "immich"
    ];

    virtualisation.oci-containers.containers = {
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
        extraOptions = ["--memory=4g"];
        volumes = ["/mnt/Data/immich/ml-cache:/cache"];
      };

      immich-valkey = {
        image = "valkey/valkey:9-alpine@sha256:de31910896150d5e754a07d57d227cfdde4e258ddd0d1aa4607f2d2f95843715";
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
    };

    systemd.services = {
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
    };
  };
}
