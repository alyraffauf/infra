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
      base.enable = true;
      backups.enable = true;
      btrfs.enable = true;
      dataShare.enable = true;
      k3s.enable = false;
      localeEnUs.enable = true;
      swap.enable = true;
      vps.enable = true;
      wireguardK3s.enable = true;
    };
    program = {
      lanzaboote.enable = true;
      docker.enable = true;
    };
    service = {
      alloy.enable = true;
      caddy.enable = true;
      fail2ban.enable = true;
      prometheusNode.enable = true;
      syncthing.enable = true;
      tailscale.enable = true;
    };
    users.aly.enable = true;
  };
}
