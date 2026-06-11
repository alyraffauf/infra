{
  flake.modules.nixos.amd-gpu = {
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
