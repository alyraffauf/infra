_: {
  flake.nixosModules.default = {
    lib,
    self,
    ...
  }: let
    tnet = "narwhal-snapper.ts.net";
    rootKeyFiles = lib.filterAttrs (
      fileName: fileType:
        fileType
        == "regular"
        && lib.hasPrefix "root_" fileName
        && lib.hasSuffix ".pub" fileName
    ) (builtins.readDir "${self}/keys");
    aliases = {
      jubilife = ["jubilife.cute" "lilycove" "lilycove.local" "lilycove.${tnet}"];
      pastoria = ["pastoria.cute"];
      snowpoint = ["snowpoint.cute" "dewford" "dewford.local" "dewford.${tnet}"];
    };
  in {
    programs.ssh.knownHosts = lib.mapAttrs' (fileName: _fileType: let
      hostName = lib.removeSuffix ".pub" (lib.removePrefix "root_" fileName);
    in
      lib.nameValuePair hostName {
        hostNames = [hostName "${hostName}.local" "${hostName}.${tnet}"] ++ (aliases.${hostName} or []);
        publicKeyFile = "${self}/keys/${fileName}";
      })
    rootKeyFiles;
  };
}
