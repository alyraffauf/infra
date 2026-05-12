{config, ...}: let
  dataDirectory = "/mnt/Data";
  tnet = "narwhal-snapper.ts.net";
in {
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

      "photoprism.${tnet}".extraConfig = ''
        bind tailscale/photoprism
        encode zstd gzip
        reverse_proxy jubilife:2342
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

    photoprism = {
      enable = true;
      originalsPath = "/mnt/Media/Photos/";
      address = "0.0.0.0";
      passwordFile = config.sops.secrets.photoprismAdminPass.path;

      settings = {
        PHOTOPRISM_SITE_URL = "https://photoprism.narwhal-snapper.ts.net";
        PHOTOPRISM_UPLOAD_NSFW = "true";
      };
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

    xserver.xkb.options = "ctrl:nocaps";
  };
}
