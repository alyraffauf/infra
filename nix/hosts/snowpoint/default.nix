{
  config,
  self,
  ...
}: {
  imports = [
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
      "config=${config.sops.secrets.rclone-b2.path}"
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
  system.stateVersion = "25.11";

  services = {
    qemuGuest.enable = true;

    navidrome = {
      enable = true;
      environmentFile = config.sops.secrets.navidrome.path;

      settings = {
        Address = "0.0.0.0";
        DefaultTheme = "Auto";
        EnableUserEditing = false;
        MusicFolder = "/mnt/Media/Music";
        Port = 4533;
        SubsonicArtistParticipations = true;
        UIWelcomeMessage = "Welcome to Navidrome @ ${config.networking.hostName}";

        # SSO via traefik-forward-auth in the cluster (auth.cute.haus).
        # TrustedSources is checked against the immediate TCP source — the
        # traefik pod inside the k3s pod CIDR — not against X-Forwarded-For.
        # Subsonic mobile clients hit caddy directly from the tailnet and
        # don't send the header; they fall back to local username/password.
        ExtAuth = {
          UserHeader = "X-Forwarded-User";
          TrustedSources = builtins.concatStringsSep "," [
            "100.64.0.0/10" # tailnet
            "10.42.0.0/16" # k3s pod CIDR (traefik)
          ];
        };
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
      autoUpgrade = {
        enable = true;
        dates = "03:30";
      };

      backups.enable = true;
      data-share.enable = true;
      media-share.enable = true;
      vps.enable = true;
      swap.enable = true;

      k3s = {
        enable = true;
        role = "agent";
        serverAddr = "https://pastoria:6443";
        zone = "cloud-netcup";
        ingress = true;
      };
    };

    programs.nix.enable = true;

    services = {
      plex.enable = true;
      prometheusNode.enable = true;
      alloy.enable = true;

      syncthing = {
        enable = true;
        certFile = config.sops.secrets.syncthingCert.path;
        keyFile = config.sops.secrets.syncthingKey.path;
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
