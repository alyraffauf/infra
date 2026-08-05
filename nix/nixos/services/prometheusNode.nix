{
  config,
  lib,
  ...
}: {
  options.myNixOs.service.prometheusNode.enable = lib.mkEnableOption "Prometheus node exporter";

  config = lib.mkIf config.myNixOs.service.prometheusNode.enable {
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
