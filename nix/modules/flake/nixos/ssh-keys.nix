_: {
  flake.modules.nixos.sshKeys = {
    lib,
    self,
    ...
  }: let
    keyFiles = builtins.attrNames (builtins.readDir "${self}/keys");
  in {
    options.myNixOS.sshKeyFiles = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.path);
      description = "Cached SSH key file paths, read once to avoid repeated filesystem scans.";
      default = {
        aly = lib.map (file: "${self}/keys/${file}") (lib.filter (file: lib.hasPrefix "aly_" file) keyFiles);
        root = lib.map (file: "${self}/keys/${file}") (lib.filter (file: lib.hasPrefix "root_" file) keyFiles);
      };
    };
  };
}
