{
  config,
  lib,
  self,
  ...
}: {
  options.myNixOs.profile.base.enable = lib.mkEnableOption "base system configuration";

  config = lib.mkIf config.myNixOs.profile.base.enable {
    documentation = {
      enable = false;
      nixos.enable = false;
    };

    environment.etc."nixos".source = self;

    hardware.enableAllFirmware = true;
    networking.networkmanager.enable = true;
    security.sudo-rs.enable = true;

    services = {
      fstrim.enable = true;

      journald = {
        storage = "persistent";
        extraConfig = ''
          SystemMaxUse=500M
          MaxRetentionSec=1week
        '';
      };

      timesyncd.enable = true;
    };

    system.configurationRevision = self.rev or self.dirtyRev or null;

    systemd = {
      coredump.enable = false;
      enableEmergencyMode = false;
    };
  };
}
