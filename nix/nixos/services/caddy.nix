{self, ...}: {
  flake.modules.nixos.caddy = {
    config,
    pkgs,
    ...
  }: {
    sops.secrets.tailscaleCaddyAuth = {
      sopsFile = "${self}/secrets/tailscale.yaml";
      key = "caddy_auth_env";
    };

    networking.firewall.allowedTCPPorts = [80 443];

    services = {
      caddy = {
        enable = true;
        enableReload = false;
        environmentFile = config.sops.secrets.tailscaleCaddyAuth.path;

        globalConfig = ''
          tailscale {
            ephemeral true
          }
        '';

        package = pkgs.caddy.withPlugins {
          plugins = ["github.com/tailscale/caddy-tailscale@v0.0.0-20260106222316-bb080c4414ac"];
          hash = "sha256-XBdYjtuPVu/beIgFgFcVp6ln4r9kq0B6+4xJ8+WWYn0=";
        };
      };

      tailscale.permitCertUid = "caddy";
    };
  };
}
