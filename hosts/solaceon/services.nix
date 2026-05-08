{config, ...}: {
  services = {
    bluesky-pds = {
      enable = true;
      environmentFiles = [config.age.secrets.pds.path];
      goat.enable = true;
      pdsadmin.enable = true;
      settings.PDS_HOSTNAME = config.mySnippets.cute-haus.networkMap.aly-social.vHost;
    };
  };
}
