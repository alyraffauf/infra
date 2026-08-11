{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myNixOs.profile.observability;
  tailnet = "narwhal-snapper.ts.net";
  kubernetesOperationsDashboard = builtins.toJSON {
    annotations.list = [];
    editable = true;
    panels = [
      {
        datasource = "Kubernetes Prometheus";
        fieldConfig.defaults.unit = "short";
        gridPos = {
          h = 8;
          w = 8;
          x = 0;
          y = 0;
        };
        targets = [
          {
            expr = "sum(gotk_reconcile_condition{type=\"Ready\",status=\"True\"})";
            refId = "A";
          }
        ];
        title = "Flux resources ready";
        type = "stat";
      }
      {
        datasource = "Kubernetes Prometheus";
        fieldConfig.defaults.unit = "short";
        gridPos = {
          h = 8;
          w = 8;
          x = 8;
          y = 0;
        };
        targets = [
          {
            expr = "sum(gotk_reconcile_condition{type=\"Ready\",status=\"False\"})";
            refId = "A";
          }
        ];
        title = "Flux reconciliation failures";
        type = "stat";
      }
      {
        datasource = "Kubernetes Prometheus";
        fieldConfig.defaults.unit = "short";
        gridPos = {
          h = 8;
          w = 8;
          x = 16;
          y = 0;
        };
        targets = [
          {
            expr = "sum(increase(kube_pod_container_status_restarts_total[1h]))";
            refId = "A";
          }
        ];
        title = "Container restarts (1h)";
        type = "stat";
      }
      {
        datasource = "Kubernetes Prometheus";
        fieldConfig.defaults.unit = "short";
        gridPos = {
          h = 8;
          w = 8;
          x = 0;
          y = 8;
        };
        targets = [
          {
            expr = "sum(kube_pod_status_ready{condition=\"true\"})";
            refId = "A";
          }
        ];
        title = "Ready pods";
        type = "stat";
      }
      {
        datasource = "Kubernetes Prometheus";
        fieldConfig.defaults.unit = "short";
        gridPos = {
          h = 8;
          w = 8;
          x = 8;
          y = 8;
        };
        targets = [
          {
            expr = "sum(kube_persistentvolumeclaim_status_phase{phase=\"Pending\"})";
            refId = "A";
          }
        ];
        title = "Pending PVCs";
        type = "stat";
      }
      {
        datasource = "Kubernetes Prometheus";
        fieldConfig.defaults.unit = "percent";
        gridPos = {
          h = 8;
          w = 8;
          x = 16;
          y = 8;
        };
        targets = [
          {
            expr = "sum(kube_pod_container_resource_requests{resource=\"cpu\"}) / sum(kube_node_status_allocatable{resource=\"cpu\"})";
            refId = "A";
          }
        ];
        title = "Requested node CPU";
        type = "gauge";
      }
      {
        datasource = "Loki";
        gridPos = {
          h = 10;
          w = 24;
          x = 0;
          y = 16;
        };
        targets = [
          {
            expr = "{job=\"kubernetes-pods\"} |~ \"(?i)error\"";
            refId = "A";
          }
        ];
        title = "Recent Kubernetes error logs";
        type = "logs";
      }
    ];
    refresh = "30s";
    schemaVersion = 39;
    tags = ["kubernetes" "operations"];
    templating.list = [];
    time = {
      from = "now-6h";
      to = "now";
    };
    title = "Kubernetes Operations";
    uid = "kubernetes-operations";
  };
in {
  options.myNixOs.profile.observability.enable = lib.mkEnableOption "the Grafana, Prometheus, and Loki observability stack";

  config = lib.mkIf cfg.enable {
    myNixOs.service.caddy.enable = true;

    services = {
      caddy.virtualHosts = {
        "grafana.${tailnet}".extraConfig = ''
          bind tailscale/grafana
          reverse_proxy localhost:3010
        '';
        "loki.${tailnet}".extraConfig = ''
          bind tailscale/loki
          reverse_proxy localhost:3030
        '';
        "prometheus.${tailnet}".extraConfig = ''
          bind tailscale/prometheus
          reverse_proxy localhost:3020
        '';
      };

      grafana = {
        enable = true;
        settings = {
          security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
          server = {
            http_addr = "0.0.0.0";
            http_port = 3010;
            domain = "grafana.${tailnet}";
          };
        };
        provision = {
          enable = true;
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              access = "proxy";
              url = "https://prometheus.${tailnet}";
            }
            {
              name = "Kubernetes Prometheus";
              type = "prometheus";
              access = "proxy";
              url = "http://127.0.0.1:30220";
            }
            {
              name = "Loki";
              type = "loki";
              access = "proxy";
              url = "https://loki.${tailnet}";
            }
          ];
          dashboards.settings = {
            apiVersion = 1;
            providers = [
              {
                name = "Kubernetes Operations";
                options.path = pkgs.writeText "kubernetes-operations.json" kubernetesOperationsDashboard;
                type = "file";
              }
            ];
          };
        };
      };

      loki = {
        enable = true;
        configuration = {
          auth_enabled = false;
          server = {
            http_listen_port = 3030;
            grpc_listen_port = 0;
          };
          common = {
            instance_addr = "0.0.0.0";
            path_prefix = "/tmp/loki";
            storage.filesystem = {
              chunks_directory = "/tmp/loki/chunks";
              rules_directory = "/tmp/loki/rules";
            };
            replication_factor = 1;
            ring.kvstore.store = "inmemory";
          };
          frontend.max_outstanding_per_tenant = 2048;
          pattern_ingester.enabled = true;
          limits_config = {
            max_global_streams_per_user = 0;
            ingestion_rate_mb = 50000;
            ingestion_burst_size_mb = 50000;
            volume_enabled = true;
          };
          query_range.results_cache.cache.embedded_cache = {
            enabled = true;
            max_size_mb = 100;
          };
          schema_config.configs = [
            {
              from = "2020-10-24";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
          analytics.reporting_enabled = false;
        };
      };

      prometheus = {
        enable = true;
        globalConfig.scrape_interval = "10s";
        port = 3020;
        scrapeConfigs = [
          {
            job_name = "bazarr";
            static_configs = [{targets = ["jubilife:9708"];}];
          }
          {
            job_name = "lidarr";
            static_configs = [{targets = ["jubilife:9709"];}];
          }
          {
            job_name = "prowlarr";
            static_configs = [{targets = ["jubilife:9710"];}];
          }
          {
            job_name = "radarr";
            static_configs = [{targets = ["jubilife:9711"];}];
          }
          {
            job_name = "smartctl";
            static_configs = [
              {
                targets = ["jubilife:9633"];
                labels.instance = "jubilife";
              }
            ];
          }
          {
            job_name = "sonarr";
            static_configs = [{targets = ["jubilife:9712"];}];
          }
          {
            job_name = "node";
            static_configs = [
              {
                targets = ["snowpoint:3021"];
                labels.instance = "snowpoint";
              }
              {
                targets = ["pastoria:3021"];
                labels.instance = "pastoria";
              }
              {
                targets = ["jubilife:3021"];
                labels.instance = "jubilife";
              }
            ];
          }
        ];
      };
    };
  };
}
