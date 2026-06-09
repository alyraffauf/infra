{
  config,
  self,
  ...
}: {
  imports = [
    self.diskoConfigurations.lvm-ext4
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

  fileSystems = {};

  networking.hostName = "snowpoint";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";

  sops.secrets = {
    navidrome = {
      sopsFile = "${self}/secrets/navidrome.yaml";
      key = "env";
    };
    syncthingCert = {
      sopsFile = ../../../secrets/syncthing.yaml;
      key = "snowpoint_cert";
    };
    syncthingKey = {
      sopsFile = ../../../secrets/syncthing.yaml;
      key = "snowpoint_key";
    };
  };

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
  myDisko.installDrive = "/dev/vda";

  myNixOS = {
    base.enable = true;

    profiles = {
      autoUpgrade = {
        enable = true;
        dates = "03:30";
      };

      backups.enable = true;

      b2-mounts = {
        enable = true;
        cacheDir = "/mnt/Backblaze/.rclone-cache";
      };

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
