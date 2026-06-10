_: {
  flake.modules.nixos.auto-upgrade = {
    config,
    lib,
    ...
  }: {
    options.myAutoUpgrade = {
      operation = lib.mkOption {
        type = lib.types.str;
        default = "switch";
        description = "Operation to perform on auto-upgrade. Can be 'boot', 'switch', or 'test'.";
      };

      dates = lib.mkOption {
        type = lib.types.str;
        default = "02:00";
        description = "systemd OnCalendar expression for when the upgrade fires.";
      };

      randomizedDelaySec = lib.mkOption {
        type = lib.types.str;
        default = "0";
        description = "Random delay added on top of `dates`.";
      };
    };

    config = {
      system.autoUpgrade = {
        inherit (config.myAutoUpgrade) operation dates randomizedDelaySec;

        enable = true;
        allowReboot = true;
        flags = ["--accept-flake-config"];
        flake = config.myFlakeUrl;
        persistent = true;

        rebootWindow = {
          lower = "02:00";
          upper = "06:00";
        };
      };
    };
  };
}
