_: {
  flake.nixosModules.jubilife = {
    boot.kernelModules = ["sg"];
  };
}
