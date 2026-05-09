{
  config,
  lib,
  ...
}: {
  options.myNixOS.profiles.vps.enable = lib.mkEnableOption "vps optimizations";

  config = lib.mkIf config.myNixOS.profiles.vps.enable {
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
