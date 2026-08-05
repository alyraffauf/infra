{
  config,
  lib,
  self,
  ...
}: {
  options.myNixOs.service.tailscale = {
    enable = lib.mkEnableOption "Tailscale";

    authKeyFile = lib.mkOption {
      description = "Key file to use for authentication";
      default = config.sops.secrets.tailscaleAuthKey.path or null;
      type = lib.types.nullOr lib.types.path;
    };

    operator = lib.mkOption {
      description = "Tailscale operator name";
      default = null;
      type = lib.types.nullOr lib.types.str;
    };
  };
  config = lib.mkIf config.myNixOs.service.tailscale.enable {
    sops.secrets.tailscaleAuthKey = {
      sopsFile = "${self}/secrets/tailscale.yaml";
      key = "auth_key";
    };

    assertions = [
      {
        assertion = config.myNixOs.service.tailscale.authKeyFile != null;
        message = "config.myNixOs.service.tailscale.authKeyFile cannot be null.";
      }
    ];

    networking.firewall = {
      allowedUDPPorts = [config.services.tailscale.port];
      trustedInterfaces = [config.services.tailscale.interfaceName];
    };

    services = {
      # When caddy is also enabled, expose a tailnet-hostname vhost that
      # proxies the local syncthing UI through /syncthing/.
      caddy = lib.mkIf config.services.caddy.enable {
        virtualHosts."${config.networking.hostName}.narwhal-snapper.ts.net".extraConfig = lib.concatLines (lib.optional config.services.syncthing.enable ''
          redir /syncthing /syncthing/
          handle_path /syncthing/* {
            reverse_proxy localhost:8384 {
              header_up Host localhost
            }
          }
        '');
      };

      tailscale = {
        enable = true;
        authKeyFile = config.myNixOs.service.tailscale.authKeyFile;

        extraUpFlags =
          ["--ssh"]
          ++ lib.optional (config.myNixOs.service.tailscale.operator != null)
          "--operator ${config.myNixOs.service.tailscale.operator}";

        openFirewall = true;
        permitCertUid = lib.mkIf config.services.caddy.enable "caddy";
        useRoutingFeatures = "both";
      };
    };
  };
}
