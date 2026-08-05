{
  config,
  lib,
  ...
}: {
  options.myNixOs.program.systemdBoot.enable = lib.mkEnableOption "systemd-boot";

  config = lib.mkIf config.myNixOs.program.systemdBoot.enable {
    boot = {
      initrd.systemd.enable = lib.mkDefault true;

      loader = {
        efi.canTouchEfiVariables = lib.mkDefault true;

        systemd-boot = {
          enable = lib.mkDefault true;
          configurationLimit = lib.mkDefault 10;
        };
      };
    };
  };
}
