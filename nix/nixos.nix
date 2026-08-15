{inputs, ...}: {
  flake.nixosModules = {
    myNixOs = inputs.import-tree ./nixos;
  };
}
