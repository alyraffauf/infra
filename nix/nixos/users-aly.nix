{
  flake.modules.nixos.users-aly = {
    config,
    lib,
    ...
  }: {
    options.myUsers.aly.password = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Hashed password for aly.";
    };

    config = {
      mySshKeys.authorizedUsers.aly = ["aly"];

      users.users.aly = {
        description = "Aly Raffauf";

        extraGroups = [
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

        hashedPassword = config.myUsers.aly.password;
        isNormalUser = true;
        uid = 1000;
      };
    };
  };
}
