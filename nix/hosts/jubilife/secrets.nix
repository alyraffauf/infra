{config, ...}: {
  sops.templates."immich-config.json" = {
    owner = "immich";
    content = ''
      {
        "oauth": {
          "enabled": true,
          "issuerUrl": "https://id.cute.haus",
          "clientId": "${config.sops.placeholder.immichOauthClientId}",
          "clientSecret": "${config.sops.placeholder.immichOauthClientSecret}",
          "scope": "openid email profile",
          "buttonText": "Sign in with cute.haus",
          "autoRegister": true,
          "autoLaunch": false,
          "mobileOverrideEnabled": false,
          "mobileRedirectUri": ""
        }
      }
    '';
  };

  sops.secrets = {
    bazarrApiKey = {
      sopsFile = ../../../secrets/arr.yaml;
      key = "bazarr_api_key";
    };
    k3s = {
      sopsFile = ../../../secrets/k3s.yaml;
      key = "TOKEN";
    };
    lidarrApiKey = {
      sopsFile = ../../../secrets/arr.yaml;
      key = "lidarr_api_key";
    };
    immichOauthClientId = {
      sopsFile = ../../../secrets/immich.yaml;
      key = "oauth/client_id";
      owner = "immich";
    };
    immichOauthClientSecret = {
      sopsFile = ../../../secrets/immich.yaml;
      key = "oauth/client_secret";
      owner = "immich";
    };
    photoprismAdminPass = {
      sopsFile = ../../../secrets/photoprism.yaml;
      key = "ADMIN_PASSWORD";
    };
    prowlarrApiKey = {
      sopsFile = ../../../secrets/arr.yaml;
      key = "prowlarr_api_key";
    };
    radarrApiKey = {
      sopsFile = ../../../secrets/arr.yaml;
      key = "radarr_api_key";
    };
    rclone-b2 = {
      sopsFile = ../../../secrets/b2.yaml;
      key = "rclone_config";
    };
    restic-passwd = {
      sopsFile = ../../../secrets/restic.yaml;
      key = "PASSWORD";
    };
    sonarrApiKey = {
      sopsFile = ../../../secrets/arr.yaml;
      key = "sonarr_api_key";
    };
    syncthingCert = {
      sopsFile = ../../../secrets/syncthing.yaml;
      key = "jubilife_cert";
    };
    syncthingKey = {
      sopsFile = ../../../secrets/syncthing.yaml;
      key = "jubilife_key";
    };
    tailscaleAuthKey = {
      sopsFile = ../../../secrets/tailscale.yaml;
      key = "auth_key";
    };
  };
}
