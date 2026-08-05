{
  config,
  lib,
  ...
}: {
  options.myNixOs.profile.base.flakeUrl = lib.mkOption {
    type = lib.types.str;
    default = "github:alyraffauf/infra";
    description = "Default flake URL for this NixOS configuration.";
  };

  config = lib.mkIf config.myNixOs.profile.base.enable {
    environment.variables = {
      FLAKE = config.myNixOs.profile.base.flakeUrl;
      NH_FLAKE = config.myNixOs.profile.base.flakeUrl;
    };

    system.autoUpgrade = {
      enable = true;
      allowReboot = true;
      dates = lib.mkDefault "02:00";
      flags = ["--accept-flake-config"];
      flake = config.myNixOs.profile.base.flakeUrl;
      operation = lib.mkDefault "switch";
      persistent = true;
      randomizedDelaySec = lib.mkDefault "0";
      runGarbageCollection = true;

      rebootWindow = {
        lower = "02:00";
        upper = "06:00";
      };
    };
  };
}
