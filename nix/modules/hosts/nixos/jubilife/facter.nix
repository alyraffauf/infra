_: {
  flake.nixosModules.jubilife = {self, ...}: {
    hardware.facter.reportPath = self + "/nix/modules/hosts/nixos/jubilife/facter.json";
  };
}
