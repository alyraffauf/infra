{
  config,
  lib,
  pkgs,
  self,
  ...
}: {
  imports = [
    ./aly
    ./options.nix
  ];

  config = lib.mkIf (config.myUsers.root.enable or config.myUsers.aly.enable or config.myUsers.dustin.enable) {
    programs.fish.enable = true;

    users = {
      defaultUserShell = pkgs.fish;
      mutableUsers = false;

      users.root.openssh.authorizedKeys.keyFiles =
        lib.map (file: "${self}/publicKeys/${file}")
        (lib.filter (file: lib.hasPrefix "aly_" file)
          (builtins.attrNames (builtins.readDir "${self}/publicKeys")));
    };
  };
}
