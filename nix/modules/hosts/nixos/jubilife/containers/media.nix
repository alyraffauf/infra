_: {
  flake.nixosModules.jubilife = {inputs, ...}: {
    myNixOs.profile.backups.jobs.dizquetv.paths = ["/mnt/Data/dizquetv"];

    systemd.tmpfiles.rules = [
      "d /mnt/Data/dizquetv 0755 root root - -"
      "d /mnt/Data/plex 0755 1000 1000 - -"
    ];

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
    };

    systemd.services = {
      docker-dizquetv.unitConfig.RequiresMountsFor = ["/mnt/Data"];
      docker-plex.unitConfig.RequiresMountsFor = [
        "/mnt/Data"
        "/mnt/Media"
      ];
    };
  };
}
