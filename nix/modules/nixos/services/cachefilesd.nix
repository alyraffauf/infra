_: {
  flake.nixosModules.cachefilesd = {
    services.cachefilesd = {
      enable = true;

      extraConfig = ''
        brun 20%
        bcull 10%
        bstop 5%
      '';
    };
  };
}
