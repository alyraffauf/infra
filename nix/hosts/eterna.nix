{
  config,
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.eterna = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      fail2ban
      flake-url
      known-hosts
      locale-en-us
      njust
      recipes
      performance
      ssh-keys
      users
      alloy
      atbbs
      auto-upgrade
      b2-mounts
      backups
      beelink-mini-s12pro
      btrfs
      caddy
      cachefilesd
      data-share
      hw-base
      intel-cpu
      intel-gpu
      k3s-node
      lanzaboote
      media-share
      nix-config
      podman
      prometheus-node
      swap
      syncthing
      tailscale
      vps
      zram

      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      (
        {config, ...}: {
          fileSystems."/mnt/Storage" = {
            device = "/dev/disk/by-id/ata-CT2000BX500SSD1_2345E8842829";
            fsType = "btrfs";
            options = ["compress=zstd" "noatime" "nofail"];
          };

          networking = {
            firewall = {
              enable = true;
              allowedTCPPorts = [2049];
              allowedUDPPorts = [2049];
            };

            hostName = "eterna";
          };

          services.nfs.server = {
            enable = true;

            exports = ''
              /mnt/Storage 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,fsid=0)
            '';
          };

          powerManagement.powertop.enable = true;

          system.stateVersion = "25.11";

          myAutoUpgrade.dates = "05:00";

          myBackups.jobs = {
            syncthing-sync = {
              paths = ["/home/aly/sync"];
              repository = "rclone:b2:aly-backups/syncthing/sync";
            };
            syncthing-roms = {
              paths = [config.mySyncthing.romsPath];
              repository = "rclone:b2:aly-backups/syncthing/roms";
            };
          };

          myB2Mounts = {
            cacheDir = "/mnt/Storage/.rclone-cache";
            audioCacheSize = "10G";
            audioReadAhead = "3G";
            videoCacheSize = "200G";
            videoReadAhead = "5G";
            shares = ["Anime" "Audiobooks" "Movies" "Shows"];
          };

          myK3s = {
            role = "server";
            serverAddr = "https://pastoria:6443";
            zone = "home";
            ingress = true;
          };

          mySyncthing = {
            certFile = config.sops.secrets.syncthingCert.path;
            keyFile = config.sops.secrets.syncthingKey.path;
            user = "aly";
          };

          sops.secrets = {
            syncthingCert = {
              sopsFile = ../../secrets/syncthing.yaml;
              key = "eterna_cert";
            };
            syncthingKey = {
              sopsFile = ../../secrets/syncthing.yaml;
              key = "eterna_key";
            };
          };

          myUsers.aly.password = "$6$JTk2qi27OpA2fOAY$ZgTDg0wbmbwHUD..0xT4xYX.AR5hWQFCMVmn8G88yi3IAY7015AupovTpfy0arkI7nl/IDu5L09bzLKeXGvJC1";
        }
      )

      # disk layout
      {
        disko.devices = {
          disk = {
            vdb = {
              type = "disk";
              device = "/dev/sda";

              content = {
                type = "gpt";

                partitions = {
                  ESP = {
                    content = {
                      format = "vfat";

                      mountOptions = [
                        "defaults"
                        "umask=0077"
                      ];

                      mountpoint = "/boot";
                      type = "filesystem";
                    };

                    size = "1024M";
                    type = "EF00";
                  };

                  luks = {
                    size = "100%";

                    content = {
                      type = "luks";
                      name = "crypted";

                      content = {
                        type = "btrfs";
                        extraArgs = ["-f"];

                        subvolumes = {
                          "/root" = {
                            mountOptions = ["compress=zstd" "noatime"];
                            mountpoint = "/";
                          };

                          "persist" = {
                            mountOptions = ["compress=zstd" "noatime"];
                            mountpoint = "/persist";
                          };

                          "/home" = {
                            mountOptions = ["compress=zstd" "noatime"];
                            mountpoint = "/home";
                          };

                          "/home/.snapshots" = {
                            mountOptions = ["compress=zstd" "noatime"];
                            mountpoint = "/home/.snapshots";
                          };

                          "/nix" = {
                            mountOptions = ["compress=zstd" "noatime"];
                            mountpoint = "/nix";
                          };
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      }

      # observability
      {
        services = {
          grafana = {
            enable = true;

            settings = {
              security.secret_key = "SW2YcwTIb9zpOOhoPsMm";

              server = {
                http_addr = "0.0.0.0";
                http_port = 3010;
                domain = "grafana.narwhal-snapper.ts.net";
              };
            };

            provision = {
              enable = true;

              datasources.settings.datasources = [
                {
                  name = "Prometheus";
                  type = "prometheus";
                  access = "proxy";
                  url = "https://prometheus.narwhal-snapper.ts.net";
                }
                {
                  name = "Loki";
                  type = "loki";
                  access = "proxy";
                  url = "https://loki.narwhal-snapper.ts.net";
                }
              ];
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

                storage = {
                  filesystem = {
                    chunks_directory = "/tmp/loki/chunks";
                    rules_directory = "/tmp/loki/rules";
                  };
                };

                replication_factor = 1;

                ring = {
                  kvstore = {
                    store = "inmemory";
                  };
                };
              };

              frontend = {
                max_outstanding_per_tenant = 2048;
              };

              pattern_ingester = {
                enabled = true;
              };

              limits_config = {
                max_global_streams_per_user = 0;
                ingestion_rate_mb = 50000;
                ingestion_burst_size_mb = 50000;
                volume_enabled = true;
              };

              query_range = {
                results_cache = {
                  cache = {
                    embedded_cache = {
                      enabled = true;
                      max_size_mb = 100;
                    };
                  };
                };
              };

              schema_config = {
                configs = [
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
              };

              analytics = {
                reporting_enabled = false;
              };
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
                  {
                    targets = ["eterna:3021"];
                    labels.instance = "eterna";
                  }
                  {
                    targets = ["solaceon:3021"];
                    labels.instance = "solaceon";
                  }
                ];
              }
            ];
          };
        };
      }

      # services
      (let
        tnet = "narwhal-snapper.ts.net";
      in {
        services = {
          caddy = {
            email = "alyraffauf@fastmail.com";
            virtualHosts = {
              "grafana.${tnet}".extraConfig = ''
                bind tailscale/grafana
                encode zstd gzip
                reverse_proxy eterna:3010
              '';

              "loki.${tnet}".extraConfig = ''
                bind tailscale/loki
                encode zstd gzip
                reverse_proxy eterna:3030
              '';

              "prometheus.${tnet}".extraConfig = ''
                bind tailscale/prometheus
                encode zstd gzip
                reverse_proxy eterna:3020
              '';
            };
          };

          karakeep = {
            enable = false;

            extraEnvironment = rec {
              DISABLE_NEW_RELEASE_CHECK = "true";
              DISABLE_SIGNUPS = "true";
              INFERENCE_CONTEXT_LENGTH = "128000";
              INFERENCE_EMBEDDING_MODEL = "nomic-embed-text";
              INFERENCE_ENABLE_AUTO_SUMMARIZATION = "true";
              INFERENCE_IMAGE_MODEL = "gemma3:4b";
              INFERENCE_JOB_TIMEOUT_SEC = "600";
              INFERENCE_LANG = "english";
              INFERENCE_TEXT_MODEL = INFERENCE_IMAGE_MODEL;
              NEXTAUTH_URL = "https://karakeep.cute.haus";
              OLLAMA_BASE_URL = "https://ollama.${tnet}";
              OLLAMA_KEEP_ALIVE = "5m";
              PORT = "7020";
            };
          };

          meilisearch.settings.experimental_dumpless_upgrade = true;
        };
      })

      {
        nixpkgs = {
          overlays = [self.overlays.default];
          config.allowUnfree = true;
        };
      }
    ];
  };
}
