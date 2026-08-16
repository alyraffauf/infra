_: {
  flake.nixosModules.jubilife = {
    networking.hostName = "jubilife";
    system.stateVersion = "25.11";
  };
}
