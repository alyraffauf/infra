{
  config,
  lib,
  self,
  ...
}: let
  tnet = "narwhal-snapper.ts.net";
  pub = host: "${self}/keys/root_${host}.pub";
in {
  config = lib.mkIf config.myNixOs.profile.base.enable {
    programs.ssh.knownHosts = {
      snowpoint = {
        hostNames = ["snowpoint" "snowpoint.local" "snowpoint.${tnet}" "snowpoint.cute" "dewford" "dewford.local" "dewford.${tnet}"];
        publicKeyFile = pub "snowpoint";
      };

      jubilife = {
        hostNames = ["jubilife" "jubilife.local" "jubilife.${tnet}" "jubilife.cute" "lilycove" "lilycove.local" "lilycove.${tnet}"];
        publicKeyFile = pub "jubilife";
      };

      pastoria = {
        hostNames = ["pastoria" "pastoria.local" "pastoria.${tnet}" "pastoria.cute"];
        publicKeyFile = pub "pastoria";
      };

      eterna = {
        hostNames = ["eterna" "eterna.local" "eterna.${tnet}" "eterna.cute" "mauville" "mauville.local" "mauville.${tnet}"];
        publicKeyFile = pub "eterna";
      };

      petalburg = {
        hostNames = ["petalburg" "petalburg.local" "petalburg.${tnet}"];
        publicKeyFile = pub "petalburg";
      };
    };
  };
}
