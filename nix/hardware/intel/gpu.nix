{
  flake.modules.nixos.intel-gpu = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.myIntelGpu.driver = lib.mkOption {
      description = "Intel GPU driver to use";
      type = lib.types.enum ["i915" "xe"];
      default = "i915";
    };

    config = {
      boot.initrd.kernelModules = [config.myIntelGpu.driver];

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "iHD";
        VDPAU_DRIVER = "va_gl";
      };

      hardware = {
        intel-gpu-tools.enable = true;

        graphics = {
          enable = true;

          extraPackages = [
            (pkgs.intel-vaapi-driver.override {enableHybridCodec = true;})
            pkgs.intel-compute-runtime
            pkgs.intel-media-driver
            pkgs.intel-ocl
            pkgs.libvdpau-va-gl
            pkgs.vpl-gpu-rt
          ];

          extraPackages32 = [
            pkgs.driversi686Linux.intel-media-driver
            (pkgs.driversi686Linux.intel-vaapi-driver.override {enableHybridCodec = true;})
            pkgs.driversi686Linux.libvdpau-va-gl
          ];
        };
      };

      services.xserver.videoDrivers = ["modesetting"];
    };
  };
}
