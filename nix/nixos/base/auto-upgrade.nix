{
  flake.modules.nixos.base = {
    config,
    lib,
    ...
  }: {
    options.myFlakeUrl = lib.mkOption {
      type = lib.types.str;
      default = "github:alyraffauf/cute.haus";
      description = "Default flake URL for this NixOS configuration.";
    };

    config = {
      environment.variables = {
        FLAKE = config.myFlakeUrl;
        NH_FLAKE = config.myFlakeUrl;
      };

      system.autoUpgrade = {
        enable = true;
        allowReboot = true;
        dates = lib.mkDefault "02:00";
        flags = ["--accept-flake-config"];
        flake = config.myFlakeUrl;
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
  };
}
