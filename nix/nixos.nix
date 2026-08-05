{inputs, ...}: {
  flake.nixosModules = {
    myHw = inputs.import-tree ./hardware;
    myNixOs = inputs.import-tree ./nixos;
  };
}
