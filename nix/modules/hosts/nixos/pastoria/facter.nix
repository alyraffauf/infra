_: {
  flake.nixosModules.pastoria = {self, ...}: {
    hardware.facter.reportPath = self + "/nix/modules/hosts/nixos/pastoria/facter.json";
  };
}
