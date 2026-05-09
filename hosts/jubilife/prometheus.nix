{config, ...}: {
  services.prometheus.exporters = {
    exportarr-bazarr = {
      enable = true;
      apiKeyFile = config.sops.secrets.bazarrApiKey.path;
      port = 9708;
      url = "https://bazarr.narwhal-snapper.ts.net";
    };

    exportarr-lidarr = {
      enable = true;
      apiKeyFile = config.sops.secrets.lidarrApiKey.path;
      port = 9709;
      url = "https://lidarr.narwhal-snapper.ts.net";
    };

    exportarr-prowlarr = {
      enable = true;
      apiKeyFile = config.sops.secrets.prowlarrApiKey.path;
      port = 9710;
      url = "https://prowlarr.narwhal-snapper.ts.net";
    };

    exportarr-radarr = {
      enable = true;
      apiKeyFile = config.sops.secrets.radarrApiKey.path;
      port = 9711;
      url = "https://radarr.narwhal-snapper.ts.net";
    };

    exportarr-sonarr = {
      enable = true;
      apiKeyFile = config.sops.secrets.sonarrApiKey.path;
      port = 9712;
      url = "https://sonarr.narwhal-snapper.ts.net";
    };

    smartctl.enable = true;
  };
}
