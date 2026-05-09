# Host-key pinning for ssh between hosts. Was previously sourced from
# the snippets flake (`mySnippets.ssh.knownHosts`); inlined here so we
# can drop the secrets-as-flake-input dep.
{
  config,
  self,
  ...
}: let
  tnet = config.mySnippets.tailnet.name;
  pub = host: "${self}/keys/root_${host}.pub";
in {
  programs.ssh.knownHosts = {
    snowpoint = {
      hostNames = ["snowpoint" "snowpoint.local" "snowpoint.${tnet}" "dewford" "dewford.local" "dewford.${tnet}"];
      publicKeyFile = pub "snowpoint";
    };
    celestic = {
      hostNames = ["celestic" "celestic.local" "celestic.${tnet}" "evergrande" "evergrande.local" "evergrande.${tnet}"];
      publicKeyFile = pub "celestic";
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
