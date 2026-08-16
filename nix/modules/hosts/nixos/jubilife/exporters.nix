_: {
  flake.nixosModules.jubilife = {
    config,
    lib,
    self,
    ...
  }: let
    tailnet = "narwhal-snapper.ts.net";
    exporters = {
      bazarr = {
        apiKey = "bazarr_api_key";
        port = 9708;
      };
      lidarr = {
        apiKey = "lidarr_api_key";
        port = 9709;
      };
      prowlarr = {
        apiKey = "prowlarr_api_key";
        port = 9710;
      };
      radarr = {
        apiKey = "radarr_api_key";
        port = 9711;
      };
      sonarr = {
        apiKey = "sonarr_api_key";
        port = 9712;
      };
    };
  in {
    sops.secrets =
      lib.mapAttrs' (serviceName: service: {
        name = "${serviceName}ApiKey";
        value = {
          sopsFile = "${self}/secrets/arr.yaml";
          key = service.apiKey;
        };
      })
      exporters;
    services.prometheus.exporters =
      (lib.mapAttrs' (serviceName: service: {
          name = "exportarr-${serviceName}";
          value = {
            enable = true;
            apiKeyFile = config.sops.secrets."${serviceName}ApiKey".path;
            inherit (service) port;
            url = "https://${serviceName}.${tailnet}";
          };
        })
        exporters)
      // {smartctl.enable = true;};
  };
}
