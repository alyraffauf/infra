{
  config,
  lib,
  ...
}: {
  options.myNixOS.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN service";

    authKeyFile = lib.mkOption {
      description = "Key file to use for authentication";
      default = config.sops.secrets.tailscaleAuthKey.path or null;
      type = lib.types.nullOr lib.types.path;
    };

    caddy.enable = lib.mkEnableOption "serving supported local services on Tailnet with Caddy";

    operator = lib.mkOption {
      description = "Tailscale operator name";
      default = null;
      type = lib.types.nullOr lib.types.str;
    };
  };

  config = lib.mkIf config.myNixOS.services.tailscale.enable {
    assertions = [
      {
        assertion = config.myNixOS.services.tailscale.authKeyFile != null;
        message = "config.tailscale.authKeyFile cannot be null.";
      }
    ];

    networking.firewall = {
      allowedUDPPorts = [config.services.tailscale.port];
      trustedInterfaces = [config.services.tailscale.interfaceName];
    };

    services = {
      caddy = lib.mkIf config.myNixOS.services.tailscale.caddy.enable {
        enable = true;

        virtualHosts = {
          "${config.networking.hostName}.${config.mySnippets.tailnet.name}".extraConfig = let
            syncthing = ''
              redir /syncthing /syncthing/
              handle_path /syncthing/* {
                reverse_proxy localhost:8384 {
                  header_up Host localhost
                }
              }
            '';
          in
            lib.concatLines (
              lib.optional config.services.syncthing.enable syncthing
            );
        };
      };

      tailscale = {
        enable = true;
        inherit (config.myNixOS.services.tailscale) authKeyFile;

        extraUpFlags =
          ["--ssh"]
          ++ lib.optional (config.myNixOS.services.tailscale.operator != null)
          "--operator ${config.myNixOS.services.tailscale.operator}";

        openFirewall = true;
        permitCertUid = lib.mkIf config.services.caddy.enable "caddy";
        useRoutingFeatures = "both";
      };
    };

    myNixOS.programs.njust.recipes.tailscale = ''
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
  };
}
