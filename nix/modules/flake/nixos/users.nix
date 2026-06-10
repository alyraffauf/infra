_: {
  flake.modules.nixos.users = {
    config,
    lib,
    pkgs,
    ...
  }: let
    mkUser = user: {
      enable = lib.mkEnableOption "${user}.";

      password = lib.mkOption {
        default = null;
        description = "Hashed password for ${user}.";
        type = lib.types.nullOr lib.types.str;
      };
    };
  in {
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

      root.enable = lib.mkEnableOption "root user configuration." // {default = true;};
      aly = mkUser "aly";
    };

    config = lib.mkMerge [
      (lib.mkIf (config.myUsers.root.enable or config.myUsers.aly.enable or config.myUsers.dustin.enable) {
        programs.fish.enable = true;

        users = {
          defaultUserShell = pkgs.fish;
          mutableUsers = false;

          users.root.openssh.authorizedKeys.keyFiles = config.myNixOS.sshKeyFiles.aly;
        };
      })

      (lib.mkIf config.myUsers.aly.enable {
        users.users.aly = {
          description = "Aly Raffauf";
          extraGroups = config.myUsers.defaultGroups;
          hashedPassword = config.myUsers.aly.password;
          isNormalUser = true;

          openssh.authorizedKeys.keyFiles = config.myNixOS.sshKeyFiles.aly;

          uid = 1000;
        };
      })
    ];
  };
}
