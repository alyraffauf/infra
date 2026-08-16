_: {
  flake.nixosModules.default = {
    services.timesyncd.enable = true;
  };
}
