_: {
  flake.modules.nixos.users = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: {
    options.myUsers = {
      defaultGroups = lib.mkOption {
        description = "Default groups for desktop users.";
        default = [
          "cdrom"
          "dialout"
          "docker"
          "libvirtd"
          "lp"
          "networkmanager"
          "plugdev"
          "scanner"
          "transmission"
          "video"
          "wheel"
        ];
      };

      aly.password = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Hashed password for aly.";
      };
    };

    config = lib.mkMerge [
      {
        programs.fish.enable = true;

        users = {
          defaultUserShell = pkgs.fish;
          mutableUsers = false;

          users = {
            aly = {
              description = "Aly Raffauf";
              extraGroups = config.myUsers.defaultGroups;
              hashedPassword = config.myUsers.aly.password;
              isNormalUser = true;
              uid = 1000;
            };
          };
        };
      }
      (lib.optionalAttrs (options ? mySshKeys) {
        mySshKeys.authorizedUsers.aly = ["aly"];
      })
    ];
  };
}
