{lib, ...}: let
  nodes = {
    pastoria = "10.254.1.1";
    mauville = "10.254.1.2";
    rustboro = "10.254.1.3";
    sootopolis = "10.254.1.4";
    fortree = "10.254.1.5";
    fallarbor = "10.254.1.6";
  };
  coreDnsHosts = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: address: "    ${address} ${name}.hoenn") nodes);
in {
  flake.nixosModules.wireguardHoenn = {
    config,
    self,
    ...
  }: {
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    sops.secrets.wireguard-hoenn-private = {
      sopsFile = self + "/secrets/wireguard-hoenn.yaml";
      key = "pastoria";
      mode = "0400";
    };

    networking = {
      firewall = {
        allowedUDPPorts = [51821];
        trustedInterfaces = ["wg-hoenn"];
      };

      wireguard.interfaces.wg-hoenn = {
        ips = ["10.254.1.1/24"];
        listenPort = 51821;
        privateKeyFile = config.sops.secrets.wireguard-hoenn-private.path;

        peers = [
          {
            allowedIPs = ["10.254.1.2/32"];
            publicKey = "DLphP2R9EJ2TbIgaabt5ExQ461TdYX2EjlMsphxkVj8=";
          }
          {
            allowedIPs = ["10.254.1.3/32"];
            publicKey = "ZhpSQzxRmKrp3Tsny9rGP1PCtcP/zghdRoQJBPWPGGQ=";
          }
          {
            allowedIPs = ["10.254.1.4/32"];
            publicKey = "ezW8vZQUpvcb2ltr8BOIn+iZ/lXI0mvNLs49ZiaZnCA=";
          }
          {
            allowedIPs = ["10.254.1.5/32"];
            publicKey = "rquW00TzyERo86qdjA+Xc4dtFfNQIidxxIkp9Y6hSBY=";
          }
          {
            allowedIPs = ["10.254.1.6/32"];
            publicKey = "ZbPq07drguGi6udpyBj1zOsyoxQzcm4awstyWIJRzAQ=";
          }
        ];
      };
    };

    services.coredns = {
      enable = true;
      config = lib.concatStringsSep "\n" [
        "hoenn:53 {"
        "  bind ${nodes.pastoria}"
        "  hosts {"
        coreDnsHosts
        "  }"
        "}"
      ];
    };

    systemd.services.coredns = {
      after = ["wireguard-wg-hoenn.service"];
      requires = ["wireguard-wg-hoenn.service"];
    };
  };
}
