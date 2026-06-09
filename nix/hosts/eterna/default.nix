{config, ...}: {
  fileSystems."/mnt/Storage" = {
    device = "/dev/disk/by-id/ata-CT2000BX500SSD1_2345E8842829";
    fsType = "btrfs";
    options = ["compress=zstd" "noatime" "nofail"];
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
  myHardware.beelink.mini.s12pro.enable = true;

  myNixOS = {
    base.enable = true;

    profiles = {
      autoUpgrade = {
        enable = true;
        dates = "05:00";
      };

      backups.enable = true;
      btrfs.enable = true;

      b2-mounts = {
        enable = true;
        cacheDir = "/mnt/Storage/.rclone-cache";
        audioCacheSize = "10G";
        audioReadAhead = "3G";
        videoCacheSize = "200G";
        videoReadAhead = "5G";
        shares = ["Anime" "Audiobooks" "Movies" "Shows"];
      };

      data-share.enable = true;

      k3s = {
        enable = true;
        role = "server";
        serverAddr = "https://pastoria:6443";
        zone = "home";
        ingress = true;
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
      alloy.enable = true;

      syncthing = {
        enable = true;
        certFile = config.sops.secrets.syncthingCert.path;
        keyFile = config.sops.secrets.syncthingKey.path;
        user = "aly";
      };

      tailscale.enable = true;
    };
  };

  sops.secrets = {
    syncthingCert = {
      sopsFile = ../../../secrets/syncthing.yaml;
      key = "eterna_cert";
    };
    syncthingKey = {
      sopsFile = ../../../secrets/syncthing.yaml;
      key = "eterna_key";
    };
  };

  myUsers.aly = {
    enable = true;
    password = "$6$JTk2qi27OpA2fOAY$ZgTDg0wbmbwHUD..0xT4xYX.AR5hWQFCMVmn8G88yi3IAY7015AupovTpfy0arkI7nl/IDu5L09bzLKeXGvJC1";
  };
}
