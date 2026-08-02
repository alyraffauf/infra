{self, ...}: {
  flake.modules.nixos.wireguard-k3s = {
    config,
    lib,
    ...
  }: let
    cfg = config.myWireguardK3s;
    nodes = {
      jubilife = {
        address = "10.254.0.1";
        homeEndpoint = "192.168.1.138:51820";
        listenPort = 51820;
        publicKey = "6gZ8YuQXYq1cQKOWisgjeEwOX2KLYZNnGY6vIW5wvGU=";
      };
      pastoria = {
        address = "10.254.0.2";
        listenPort = 51820;
        endpoint = "51.81.87.134:51820";
        publicKey = "5bEvmgY36NiZalRwEy9h0oZJqsJvPC+zmaD78GOLuUo=";
      };
      snowpoint = {
        address = "10.254.0.3";
        listenPort = 51820;
        endpoint = "152.53.90.225:51820";
        publicKey = "t1mErjV5oE4ucLtRt2UHiPShkPluxp+uM2+pRoswVS8=";
      };
      eterna = {
        address = "10.254.0.4";
        homeEndpoint = "192.168.1.248:51821";
        listenPort = 51821;
        publicKey = "jZV8JNiEx+mZ6BzYFAxqUPy1a78AZkdgTAt7VBClhGE=";
      };
    };
    node = nodes.${config.networking.hostName};
    isHomeNode = node ? homeEndpoint;
  in {
    options.myWireguardK3s.enable = lib.mkEnableOption "the dedicated k3s WireGuard mesh";

    config = lib.mkIf cfg.enable {
      sops.secrets.wireguard-k3s-private = {
        sopsFile = "${self}/secrets/wireguard-k3s.yaml";
        key = config.networking.hostName;
      };

      networking = {
        firewall = {
          allowedUDPPorts = [node.listenPort];
          # k3s control-plane, Flannel, and kubelet traffic use this private
          # mesh after the transport migration.
          trustedInterfaces = ["wg-k3s"];
        };
        hosts =
          lib.mapAttrs' (name: peer: {
            name = peer.address;
            value = ["${name}.cute"];
          })
          nodes;
        wireguard.interfaces.wg-k3s = {
          ips = ["${node.address}/24"];
          inherit (node) listenPort;
          privateKeyFile = config.sops.secrets.wireguard-k3s-private.path;
          peers = lib.mapAttrsToList (_name: peer:
            {
              allowedIPs = ["${peer.address}/32"];
              persistentKeepalive = 25;
              inherit (peer) publicKey;
            }
            // lib.optionalAttrs (peer ? endpoint || (isHomeNode && peer ? homeEndpoint)) {
              endpoint =
                if isHomeNode && peer ? homeEndpoint
                then peer.homeEndpoint
                else peer.endpoint;
            }) (lib.filterAttrs (name: _: name != config.networking.hostName) nodes);
        };
      };
    };
  };
}
