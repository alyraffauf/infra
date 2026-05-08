{
  config,
  lib,
  pkgs,
  self,
  ...
}: let
  dataDirectory = "/mnt/Data";
in {
  imports = [
    ./backups.nix
    ./b2.nix
    ./home.nix
    ./oci.nix
    ./prometheus.nix
    ./secrets.nix
    ./services.nix
    self.diskoConfigurations.luks-btrfs-subvolumes
    self.nixosModules.locale-en-us
  ];

  boot = {
    initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" "r8169"];
    kernelModules = ["sg"];
  };

  environment.systemPackages = with pkgs; [
    abcde
    ffmpeg-full
    flac
    handbrake
    makemkv
    mediainfo
    mkvtoolnix
  ];

  fileSystems = {
    "/mnt/Data" = {
      device = "/dev/disk/by-id/ata-CT4000BX500SSD1_2447E9959972";
      fsType = "btrfs";
      options = ["compress=zstd" "noatime" "nofail"];
    };

    "/mnt/Media" = {
      device = "/dev/disk/by-id/ata-ST14000NM001G-2KJ103_ZL201XNJ-part1";
      fsType = "btrfs";
      options = ["subvol=@media" "compress=zstd" "noatime" "nofail"];
    };
  };

  networking = {
    firewall.allowedTCPPorts = [2342 5143 6881];
    hostName = "jubilife";
  };

  services.udev.extraRules = let
    mkRule = as: lib.concatStringsSep ", " as;
    mkRules = rs: lib.concatStringsSep "\n" rs;
  in
    mkRules [
      (mkRule [
        ''ACTION=="add|change"''
        ''SUBSYSTEM=="block"''
        ''KERNEL=="sd[a-z]"''
        ''ATTR{queue/rotational}=="1"''
        ''RUN+="${pkgs.hdparm}/bin/hdparm -B 90 -S 41 /dev/%k"''
      ])
    ];

  system.stateVersion = "25.11";
  time.timeZone = "America/New_York";
  myDisko.installDrive = "/dev/disk/by-id/nvme-PNY_CS2130_1TB_SSD_PNY211821050701050CC";

  myHardware = {
    amd.cpu.enable = true;
    intel.gpu.enable = true;
    profiles.base.enable = true;
  };

  myNixOS = {
    base.enable = true;

    profiles = {
      arr = {
        enable = true;
        dataDir = "/mnt/Data";
      };

      autoUpgrade.enable = true;
      backups.enable = true;
      btrfs.enable = true;
      vps.enable = true;
      swap.enable = true;
      zram.enable = true;

      k3s = {
        enable = true;
        role = "agent";
        serverAddr = "https://solaceon:6443";
        zone = "home";
      };
    };

    programs = {
      lanzaboote.enable = true;
      nix.enable = true;
      podman.enable = true;
    };

    services = {
      caddy.enable = true;

      forgejo-runner = {
        enable = true;
        dockerContainers = 3;
        nativeRunners = 2;
      };

      plex = {
        enable = true;
        dataDir = "/mnt/Data";
        tautulli.enable = true;
      };

      prometheusNode.enable = true;
      promtail.enable = true;

      qbittorrent = {
        inherit (config.mySnippets.tailnet.networkMap.qbittorrent) port;
        enable = true;
      };

      syncthing = {
        enable = true;
        certFile = config.age.secrets.syncthingCert.path;
        keyFile = config.age.secrets.syncthingKey.path;
        romsPath = "${dataDirectory}/syncthing/ROMs";
        syncROMs = true;
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
