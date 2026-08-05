{
  config,
  lib,
  ...
}: {
  options.myHw.intel.cpu.enable = lib.mkEnableOption "Intel CPU support";

  config = lib.mkIf config.myHw.intel.cpu.enable {
    boot.kernelModules = ["kvm-intel"];
    hardware.cpu.intel.updateMicrocode = true;
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
