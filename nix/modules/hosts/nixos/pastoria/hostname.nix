_: {
  flake.nixosModules.pastoria = {
    networking.hostName = "pastoria";
    system.stateVersion = "26.05";
  };
}
