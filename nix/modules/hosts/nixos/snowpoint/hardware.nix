_: {
  flake.nixosModules.snowpoint = {
    services.qemuGuest.enable = true;
  };
}
