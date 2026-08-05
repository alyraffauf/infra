{
  config,
  lib,
  ...
}: {
  options.myNixOs.users.aly = {
    enable = lib.mkEnableOption "the aly user";

    password = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Hashed password for aly.";
    };
  };

  config = lib.mkIf config.myNixOs.users.aly.enable {
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

      hashedPassword = config.myNixOs.users.aly.password;
      isNormalUser = true;
      uid = 1000;
    };
  };
}
