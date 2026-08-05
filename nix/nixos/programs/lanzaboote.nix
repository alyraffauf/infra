{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [inputs.lanzaboote.nixosModules.lanzaboote];

  options.myNixOs.program.lanzaboote.enable = lib.mkEnableOption "Lanzaboote secure boot";

  config = lib.mkIf config.myNixOs.program.lanzaboote.enable {
    boot = {
      initrd.systemd.enable = true;

      lanzaboote = {
        enable = true;
        autoEnrollKeys.enable = true;
        autoGenerateKeys.enable = true;
        configurationLimit = 10;
        pkiBundle = lib.mkDefault "/var/lib/sbctl";
      };

      loader.systemd-boot.enable = lib.mkForce false;
    };

    environment.systemPackages = [pkgs.sbctl];
  };
}
