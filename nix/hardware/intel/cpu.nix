{
  flake.modules.nixos.intel-cpu = {lib, ...}: {
    boot.kernelModules = ["kvm-intel"];
    hardware.cpu.intel.updateMicrocode = true;
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
