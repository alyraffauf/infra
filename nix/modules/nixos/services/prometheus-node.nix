_: {
  flake.nixosModules.prometheusNode = {
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
