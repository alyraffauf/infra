_: {
  flake.nixosModules.eterna = {self, ...}: {
    hardware.facter.reportPath = self + "/nix/modules/hosts/nixos/eterna/facter.json";
  };
}
