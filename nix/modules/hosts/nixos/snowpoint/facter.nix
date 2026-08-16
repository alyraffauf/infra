_: {
  flake.nixosModules.snowpoint = {self, ...}: {
    hardware.facter.reportPath = self + "/nix/modules/hosts/nixos/snowpoint/facter.json";
  };
}
