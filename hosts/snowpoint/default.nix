{
  config,
  self,
  ...
}: {
  imports = [
    ./home.nix
    ./proxy.nix
    ./secrets.nix
    self.diskoConfigurations.lvm-ext4
    self.nixosModules.locale-en-us
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "virtio_net"
        "virtio_pci"
        "virtio_mmio"
        "virtio_blk"
        "virtio_scsi"
        "9p"
        "9pnet_virtio"
      ];

      kernelModules = [
        "virtio_balloon"
        "virtio_console"
        "virtio_rng"
        "virtio_gpu"
      ];
    };

    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  fileSystems = let
    b2Options = [
      "allow_other"
      "args2env"
      "cache-dir=/mnt/Backblaze/.rclone-cache"
      "config=${config.age.secrets.rclone-b2.path}"
      "dir-cache-time=1h"
      "nodev"
      "nofail"
      "vfs-cache-mode=full"
      "vfs-write-back=10s"
      "x-systemd.after=network-online.target"
      "x-systemd.automount"
    ];

    b2ProfileOptions = {
      audio = [
        "buffer-size=128M"
        "vfs-cache-max-age=168h"
        "vfs-cache-max-size=15G"
        "vfs-read-ahead=1G"
      ];

      video = [
        "buffer-size=512M"
        "vfs-cache-max-age=336h"
        "vfs-cache-max-size=50G"
        "vfs-read-ahead=3G"
      ];
    };

    mkB2Mount = name: remote: profile: {
      "/mnt/Backblaze/${name}" = {
        device = "b2:${remote}";
        fsType = "rclone";
        options = b2Options ++ b2ProfileOptions.${profile};
      };
    };
  in
    mkB2Mount "Anime" "aly-anime" "video"
    // mkB2Mount "Audiobooks" "aly-audiobooks" "audio"
    // mkB2Mount "Movies" "aly-movies" "video"
    // mkB2Mount "Music" "aly-music" "audio"
    // mkB2Mount "Shows" "aly-shows" "video";

  networking.hostName = "snowpoint";
  nixpkgs.hostPlatform = "x86_64-linux";
  programs.ssh.knownHosts = config.mySnippets.ssh.knownHosts;
  system.stateVersion = "25.11";

  services = {
    couchdb = {
      inherit (config.mySnippets.tailnet.networkMap.couchdb) port;
      enable = true;
      bindAddress = "0.0.0.0";

      extraConfig = {
        couchdb = {
          single_node = true;
          max_document_size = 50000000;
        };

        chttpd = {
          require_valid_user = true;
          max_http_request_size = 4294967296;
          enable_cors = true;
        };

        chttpd_auth = {
          require_valid_user = true;
          authentication_redirect = "/_utils/session.html";
        };

        httpd = {
          enable_cors = true;
          "WWW-Authenticate" = "Basic realm=\"couchdb\"";
          bind_address = "0.0.0.0";
        };

        cors = {
          origins = "app://obsidian.md,capacitor://localhost,http://localhost";
          credentials = true;
          headers = "accept, authorization, content-type, origin, referer";
          methods = "GET,PUT,POST,HEAD,DELETE";
          max_age = 3600;
        };
      };
    };

    qemuGuest.enable = true;

    navidrome = {
      enable = true;
      environmentFile = config.age.secrets.navidrome.path;

      settings = {
        Address = "0.0.0.0";
        DefaultTheme = "Auto";
        MusicFolder = "/mnt/Media/Music";
        Port = config.mySnippets.tailnet.networkMap.navidrome.port;
        SubsonicArtistParticipations = true;
        UIWelcomeMessage = "Welcome to Navidrome @ ${config.networking.hostName}";
      };
    };
  };

  # Make navidrome wait for /mnt/Media + restart if necessary.
  systemd.services.navidrome.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "30s";
  };

  time.timeZone = "America/New_York";
  myDisko.installDrive = "/dev/vda";

  myNixOS = {
    base.enable = true;

    profiles = {
      autoUpgrade.enable = true;
      backups.enable = true;
      data-share.enable = true;
      media-share.enable = true;
      vps.enable = true;
      swap.enable = true;
    };

    programs.nix.enable = true;

    services = {
      caddy.enable = true;
      plex.enable = true;
      prometheusNode.enable = true;
      promtail.enable = true;

      syncthing = {
        enable = true;
        certFile = config.age.secrets.syncthingCert.path;
        keyFile = config.age.secrets.syncthingKey.path;
        syncROMs = false;
        user = "aly";
      };

      tailscale.enable = true;
    };
  };

  myUsers.aly = {
    enable = true;
    password = "$6$JTk2qi27OpA2fOAY$ZgTDg0wbmbwHUD..0xT4xYX.AR5hWQFCMVmn8G88yi3IAY7015AupovTpfy0arkI7nl/IDu5L09bzLKeXGvJC1";
  };
}
