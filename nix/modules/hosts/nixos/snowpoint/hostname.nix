_: {
  flake.nixosModules.snowpoint = {
    networking.hostName = "snowpoint";
    system.stateVersion = "25.11";
  };
}
