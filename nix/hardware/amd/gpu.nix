{
  config,
  lib,
  ...
}: {
  options.myHw.amd.gpu.enable = lib.mkEnableOption "AMD GPU support";

  config = lib.mkIf config.myHw.amd.gpu.enable {
    environment.variables = {
      DPAU_DRIVER = "radeonsi";
      GSK_RENDERER = "ngl";
    };

    hardware = {
      amdgpu = {
        initrd.enable = true;
        opencl.enable = true;
      };

      graphics.enable = true;
    };
  };
}
