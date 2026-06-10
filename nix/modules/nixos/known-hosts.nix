# Host-key pinning for ssh between hosts.
{self, ...}: let
  tnet = "narwhal-snapper.ts.net";
  pub = host: "${self}/keys/root_${host}.pub";
in {
  programs.ssh.knownHosts = {
    snowpoint = {
      hostNames = ["snowpoint" "snowpoint.local" "snowpoint.${tnet}" "dewford" "dewford.local" "dewford.${tnet}"];
      publicKeyFile = pub "snowpoint";
    };

    fallarbor = {
      hostNames = ["fallarbor" "fallarbor.local" "fallarbor.${tnet}"];
      publicKeyFile = pub "fallarbor";
    };

    fortree = {
      hostNames = ["fortree" "fortree.local" "fortree.${tnet}"];
      publicKeyFile = pub "fortree";
    };

    jubilife = {
      hostNames = ["jubilife" "jubilife.local" "jubilife.${tnet}" "lilycove" "lilycove.local" "lilycove.${tnet}"];
      publicKeyFile = pub "jubilife";
    };

    pastoria = {
      hostNames = ["pastoria" "pastoria.local" "pastoria.${tnet}"];
      publicKeyFile = pub "pastoria";
    };

    eterna = {
      hostNames = ["eterna" "eterna.local" "eterna.${tnet}" "mauville" "mauville.local" "mauville.${tnet}"];
      publicKeyFile = pub "eterna";
    };

    solaceon = {
      hostNames = ["solaceon" "solaceon.local" "solaceon.${tnet}" "mossdeep" "mossdeep.local" "mossdeep.${tnet}"];
      publicKeyFile = pub "solaceon";
    };

    petalburg = {
      hostNames = ["petalburg" "petalburg.local" "petalburg.${tnet}"];
      publicKeyFile = pub "petalburg";
    };

    rustboro = {
      hostNames = ["rustboro" "rustboro.local" "rustboro.${tnet}"];
      publicKeyFile = pub "rustboro";
    };

    slateport = {
      hostNames = ["slateport" "slateport.local" "slateport.${tnet}"];
      publicKeyFile = pub "slateport";
    };

    sootopolis = {
      hostNames = ["sootopolis" "sootopolis.local" "sootopolis.${tnet}"];
      publicKeyFile = pub "sootopolis";
    };
  };
}
