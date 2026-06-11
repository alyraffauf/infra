{
  flake.modules.nixos.amd-cpu = {
    config,
    lib,
    ...
  }: {
    boot = {
      blacklistedKernelModules = ["k10temp"];
      extraModulePackages = with config.boot.kernelPackages; [zenpower];
      kernelModules = [
        "kvm-amd"
        "zenpower"
      ];
    };

    hardware.cpu.amd.updateMicrocode = true;
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
