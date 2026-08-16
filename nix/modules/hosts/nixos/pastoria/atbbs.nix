_: {
  flake.nixosModules.pastoria = {pkgs, ...}: {
    networking.firewall.allowedTCPPorts = [23];

    systemd.services.atbbs-telnet = {
      description = "TCP proxy for atbbs telnet";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:23,fork,reuseaddr TCP:jubilife:2323";
        Restart = "always";
      };
    };
  };
}
