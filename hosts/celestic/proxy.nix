{config, ...}: {
  security.acme = {
    acceptTerms = true;
    defaults.email = "alyraffauf@fastmail.com";
  };

  services = {
    caddy = {
      email = "alyraffauf@fastmail.com";

      virtualHosts = {
        "morsels.blue" = {
          extraConfig = ''
            encode gzip zstd
            reverse_proxy ${config.mySnippets.cute-haus.networkMap.morsels.hostName}:${toString config.mySnippets.cute-haus.networkMap.morsels.port}
          '';

          serverAliases = ["www.morsels.blue"];
        };
      };
    };
  };
}
