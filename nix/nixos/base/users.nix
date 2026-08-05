{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.myNixOs.profile.base.enable {
    mySshKeys.authorizedUsers.root = ["aly"];

    users = {
      defaultUserShell = pkgs.fish;
      mutableUsers = false;
    };
  };
}
