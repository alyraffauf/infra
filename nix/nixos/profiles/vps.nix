_: {
  flake.modules.nixos.vps = {
    documentation = {
      enable = false;
      nixos.enable = false;
    };

    services.journald = {
      storage = "persistent";

      extraConfig = ''
        SystemMaxUse=500M
        MaxRetentionSec=1week
      '';
    };
  };
}
