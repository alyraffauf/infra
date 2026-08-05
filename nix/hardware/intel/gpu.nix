{
  config,
  lib,
  pkgs,
  ...
}: {
  options.myHw.intel.gpu = {
    enable = lib.mkEnableOption "Intel GPU support";

    driver = lib.mkOption {
      description = "Intel GPU driver to use";
      type = lib.types.enum ["i915" "xe"];
      default = "i915";
    };
  };

  config = lib.mkIf config.myHw.intel.gpu.enable {
    boot.initrd.kernelModules = [config.myHw.intel.gpu.driver];

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };

    hardware = {
      intel-gpu-tools.enable = true;

      graphics = {
        enable = true;

        extraPackages = [
          (pkgs.intel-vaapi-driver.override {enableHybridCodec = true;})
          pkgs.intel-compute-runtime
          pkgs.intel-media-driver
        ];
      };
    };

    services.xserver.videoDrivers = ["modesetting"];

    services.k3s.extraFlags = lib.mkIf config.services.k3s.enable [
      "--node-label=cute.haus/intel-gpu=true"
    ];
  };
}
