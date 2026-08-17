_: {
  flake.nixosModules.jubilife = {
    networking.firewall = {
      allowedTCPPorts = [2342 5143 6881 32400 8324 32443];
      allowedUDPPorts = [1900 32410 32412 32413 32414];
      extraInputRules = ''
        -s 10.42.0.0/16 -p tcp --dport 3900 -j ACCEPT
        -s 10.42.0.0/16 -p tcp --dport 2049 -j ACCEPT
        -s 10.42.0.0/16 -p udp --dport 2049 -j ACCEPT
      '';
      interfaces.nextcloud0.allowedTCPPorts = [3900];
    };
  };
}
