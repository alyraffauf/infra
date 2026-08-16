_: {
  flake.nixosModules.default = {
    systemd = {
      coredump.enable = false;
      enableEmergencyMode = false;
    };
  };
}
