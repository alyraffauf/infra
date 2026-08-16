_: {
  flake.nixosModules.default = {
    services.journald = {
      storage = "persistent";
      extraConfig = ''
        SystemMaxUse=500M
        MaxRetentionSec=1week
      '';
    };
  };
}
