_: {
  flake.nixosModules.default = {
    services.journald = {
      storage = "persistent";
      extraConfig = ''
        SystemMaxUse=1G
        SystemKeepFree=1G
        MaxRetentionSec=1week
      '';
    };
  };
}
