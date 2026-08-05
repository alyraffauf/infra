{
  config,
  lib,
  ...
}: {
  options.myHw.amd.cpu.enable = lib.mkEnableOption "AMD CPU support";

  config = lib.mkIf config.myHw.amd.cpu.enable {
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
