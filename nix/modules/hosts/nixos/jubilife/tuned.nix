_: {
  flake.nixosModules.jubilife = {
    services.tuned = {
      enable = true;
      settings.dynamic_tuning = true;
    };
  };
}
