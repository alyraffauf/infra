{self, ...}: {
  flake.modules.nixos.tailscale = {
    config,
    lib,
    ...
  }: {
    options.myTailscale = {
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

    config = lib.mkMerge [
      {
        sops.secrets.tailscaleAuthKey = {
          sopsFile = "${self}/secrets/tailscale.yaml";
          key = "auth_key";
        };

        assertions = [
          {
            assertion = config.myTailscale.authKeyFile != null;
            message = "config.myTailscale.authKeyFile cannot be null.";
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
            inherit (config.myTailscale) authKeyFile;

            extraUpFlags =
              ["--ssh"]
              ++ lib.optional (config.myTailscale.operator != null)
              "--operator ${config.myTailscale.operator}";

            openFirewall = true;
            permitCertUid = lib.mkIf config.services.caddy.enable "caddy";
            useRoutingFeatures = "both";
          };
        };
      }

      {
        myRecipes.tailscale = ''
          # Connect to Mullvad NYC
          [group('tailscale')]
          enable-mullvad:
              @echo "Connecting to Mullvad NYC exit node..."
              tailscale set --exit-node=us-nyc-wg-301.mullvad.ts.net

          # Disconnect from Mullvad NYC
          [group('tailscale')]
          disable-mullvad:
              @echo "Disconnecting from exit node..."
              tailscale set --exit-node=

          # Show Tailscale status
          [group('tailscale')]
          ts-status:
              tailscale status
        '';
      }
    ];
  };
}
