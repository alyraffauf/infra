_: {
  flake.nixosModules.intelGpu = {pkgs, ...}: {
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
  };
}
