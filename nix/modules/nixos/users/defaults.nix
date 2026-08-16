_: {
  flake.nixosModules.default = {pkgs, ...}: {
    mySshKeys.authorizedUsers.root = ["aly"];

    users = {
      defaultUserShell = pkgs.fish;
      mutableUsers = false;
    };
  };
}
