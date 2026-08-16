_: {
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
      hosts = {
        "10.254.1.1" = ["pastoria.hoenn"];
        "10.254.1.2" = ["mauville.hoenn"];
        "10.254.1.3" = ["rustboro.hoenn"];
        "10.254.1.4" = ["sootopolis.hoenn"];
        "10.254.1.5" = ["fortree.hoenn"];
      };

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
        ];
      };
    };
  };
}
