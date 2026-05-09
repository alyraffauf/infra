{
  config,
  self,
  ...
}: {
  imports = [
    ./backups.nix
    ./disko.nix
    ./grafana.nix
    ./home.nix
    ./secrets.nix
    ./services.nix
    self.nixosModules.locale-en-us
  ];

  fileSystems = let
    b2Options = [
      "allow_other"
      "args2env"
      "cache-dir=/mnt/Storage/.rclone-cache"
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
        "vfs-cache-max-size=10G"
        "vfs-read-ahead=3G"
      ];

      video = [
        "buffer-size=512M"
        "vfs-cache-max-age=336h"
        "vfs-cache-max-size=200G"
        "vfs-read-ahead=5G"
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
    // mkB2Mount "Shows" "aly-shows" "video"
    // {
      "/mnt/Storage" = {
        device = "/dev/disk/by-id/ata-CT2000BX500SSD1_2345E8842829";
        fsType = "btrfs";
        options = ["compress=zstd" "noatime" "nofail"];
      };
    };

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [2049]; # NFS
      allowedUDPPorts = [2049];
    };

    hostName = "eterna";
  };

  services.nfs.server = {
    enable = true;

    exports = ''
      /mnt/Storage 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,fsid=0)
    '';
  };

  powerManagement.powertop.enable = true;

  system.stateVersion = "25.11";
  time.timeZone = "America/New_York";
  myHardware.beelink.mini.s12pro.enable = true;

  myNixOS = {
    base.enable = true;

    profiles = {
      autoUpgrade.enable = true;
      backups.enable = true;
      btrfs.enable = true;
      data-share.enable = true;

      k3s = {
        enable = true;
        role = "server";
        serverAddr = "https://solaceon:6443";
        tlsSans = ["solaceon" "celestic"];
        zone = "home";
      };

      media-share.enable = true;
      vps.enable = true;
      swap.enable = true;
      zram.enable = true;
    };

    programs = {
      lanzaboote.enable = true;
      nix.enable = true;
      podman.enable = true;
    };

    services = {
      caddy.enable = true;
      prometheusNode.enable = true;
      promtail.enable = true;

      syncthing = {
        enable = true;
        certFile = config.sops.secrets.syncthingCert.path;
        keyFile = config.sops.secrets.syncthingKey.path;
        user = "aly";
      };

      tailscale = {
        enable = true;
        enableCaddy = false;
      };
    };
  };

  myUsers.aly = {
    enable = true;
    password = "$6$JTk2qi27OpA2fOAY$ZgTDg0wbmbwHUD..0xT4xYX.AR5hWQFCMVmn8G88yi3IAY7015AupovTpfy0arkI7nl/IDu5L09bzLKeXGvJC1";
  };
}
