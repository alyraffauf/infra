{
  config,
  lib,
  ...
}: {
  options.myNixOs.profile.vps.enable = lib.mkEnableOption "VPS defaults";

  config = lib.mkIf config.myNixOs.profile.vps.enable {
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
