{pkgs, ...}: {
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  hardware = {
    facter.detected.graphics.enable = true;
    intel-gpu-tools.enable = true;

    graphics.extraPackages = [
      (pkgs.intel-vaapi-driver.override {enableHybridCodec = true;})
      pkgs.intel-compute-runtime
      pkgs.intel-media-driver
    ];
  };

  services = {
    k3s.extraFlags = ["--node-label=cute.haus/intel-gpu=true"];
    xserver.videoDrivers = ["modesetting"];
  };

  myNixOs = {
    profile = {
      arr.enable = true;
      b2Mounts.enable = true;
      backups.enable = true;
      base.enable = true;
      btrfs.enable = true;
      k3s.enable = true;
      localeEnUs.enable = true;
      swap.enable = true;
      wireguardK3s.enable = true;
    };
    program = {
      lanzaboote.enable = true;
      docker.enable = true;
    };
    service = {
      alloy.enable = true;
      atbbs.enable = true;
      caddy.enable = true;
      fail2ban.enable = true;
      prometheusNode.enable = true;
      qbittorrent.enable = true;
      syncthing.enable = true;
      tailscale.enable = true;
      tautulli.enable = true;
    };
    users.aly.enable = true;
  };

  myDisko.profile.luksBtrfsSubvolumes.enable = true;
}
