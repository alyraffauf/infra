_: {
  flake.modules.nixos.prometheus-node = {
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = ["systemd"];

      extraFlags = [
        "--collector.ethtool"
        "--collector.softirqs"
        "--collector.tcpstat"
        "--collector.wifi"
      ];

      port = 3021;
    };
  };
}
