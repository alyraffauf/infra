_: {
  flake.nixosModules.eterna = {
    networking.hostName = "eterna";
    system.stateVersion = "25.11";
  };
}
