{
  flake.modules.nixos.base = {pkgs, ...}: {
    config = {
      mySshKeys.authorizedUsers.root = ["aly"];

      users = {
        defaultUserShell = pkgs.fish;
        mutableUsers = false;
      };
    };
  };
}
