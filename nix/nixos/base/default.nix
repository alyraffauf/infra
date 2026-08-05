{
  config,
  lib,
  self,
  ...
}: {
  options.myNixOs.profile.base.enable = lib.mkEnableOption "base system configuration";

  config = lib.mkIf config.myNixOs.profile.base.enable {
    environment.etc."nixos".source = self;

    hardware.enableAllFirmware = true;
    networking.networkmanager.enable = true;
    security.sudo-rs.enable = true;

    services = {
      fstrim.enable = true;
      timesyncd.enable = true;
    };

    system.configurationRevision = self.rev or self.dirtyRev or null;

    systemd = {
      coredump.enable = false;
      enableEmergencyMode = false;
    };
  };
}
