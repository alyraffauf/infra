{self, ...}: {
  flake.modules.nixos.ssh-keys = {
    config,
    lib,
    ...
  }: let
    keyFiles = builtins.attrNames (builtins.readDir "${self}/keys");
    filesFor = keys: builtins.concatMap (key: config.mySshKeys.keys.${key} or []) keys;
  in {
    options.mySshKeys = {
      keys = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.path);
        description = "Cached SSH key file paths, read once to avoid repeated filesystem scans.";
        default = {
          aly = lib.map (file: "${self}/keys/${file}") (lib.filter (file: lib.hasPrefix "aly_" file) keyFiles);
          root = lib.map (file: "${self}/keys/${file}") (lib.filter (file: lib.hasPrefix "root_" file) keyFiles);
        };
      };

      authorizedUsers = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = {};
      };
    };

    config = lib.mkMerge [
      {
        mySshKeys.authorizedUsers.root = lib.mkDefault ["aly"];
        users.users.root.openssh.authorizedKeys.keyFiles = filesFor (config.mySshKeys.authorizedUsers.root or []);
      }
      (lib.mkIf (config.mySshKeys.authorizedUsers ? aly) {
        users.users.aly.openssh.authorizedKeys.keyFiles = filesFor config.mySshKeys.authorizedUsers.aly;
      })
      (lib.mkIf (config.mySshKeys.authorizedUsers ? nixbuild) {
        users.users.nixbuild.openssh.authorizedKeys.keyFiles = filesFor config.mySshKeys.authorizedUsers.nixbuild;
      })
    ];
  };
}
