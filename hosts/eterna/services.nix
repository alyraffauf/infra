{config, ...}: {
  networking = {
    firewall.allowedTCPPorts = [80 443 2379 2380 3000 6443 61208];
    firewall.allowedUDPPorts = [8472];
  };

  myNixOS.services = {
    atbbs.enable = true;
  };

  services = {
    audiobookshelf = {
      enable = true;
      host = "0.0.0.0";
      openFirewall = true;
      port = 13378;
    };

    caddy = {
      email = "alyraffauf@fastmail.com";
      virtualHosts = {
        "${config.mySnippets.tailnet.networkMap.grafana.vHost}" = {
          extraConfig = ''
            bind tailscale/grafana
            encode zstd gzip
            reverse_proxy ${config.mySnippets.tailnet.networkMap.grafana.hostName}:${toString config.mySnippets.tailnet.networkMap.grafana.port}
          '';
        };

        "${config.mySnippets.tailnet.networkMap.loki.vHost}" = {
          extraConfig = ''
            bind tailscale/loki
            encode zstd gzip
            reverse_proxy ${config.mySnippets.tailnet.networkMap.loki.hostName}:${toString config.mySnippets.tailnet.networkMap.loki.port}
          '';
        };

        "${config.mySnippets.tailnet.networkMap.prometheus.vHost}" = {
          extraConfig = ''
            bind tailscale/prometheus
            encode zstd gzip
            reverse_proxy ${config.mySnippets.tailnet.networkMap.prometheus.hostName}:${toString config.mySnippets.tailnet.networkMap.prometheus.port}
          '';
        };
      };
    };

    glance = {
      enable = true;
      openFirewall = true;

      settings = {
        pages = [
          {
            name = config.mySnippets.cute-haus.networkMap.glance.vHost;
            width = "slim";
            hide-desktop-navigation = true;
            center-vertically = true;
            columns = [
              {
                size = "full";
                widgets = [
                  {
                    type = "search";
                    autofocus = true;
                    search-engine = "kagi";
                  }
                  {
                    type = "monitor";
                    cache = "1m";
                    title = "Public Services";

                    sites = [
                      {
                        title = "Plex";
                        url = "https://${config.mySnippets.cute-haus.networkMap.plex.vHost}/";
                        check-url = "http://${config.mySnippets.cute-haus.networkMap.plex.hostName}:${toString config.mySnippets.cute-haus.networkMap.plex.port}/web/index.html";
                        icon = "di:plex";
                      }
                      {
                        title = "Ombi";
                        url = "https://${config.mySnippets.cute-haus.networkMap.ombi.vHost}/";
                        check-url = "http://${config.mySnippets.cute-haus.networkMap.ombi.hostName}:${toString config.mySnippets.cute-haus.networkMap.ombi.port}/";
                        icon = "di:ombi";
                      }
                      {
                        title = "Audiobookshelf";
                        url = "https://${config.mySnippets.cute-haus.networkMap.audiobookshelf.vHost}/";
                        check-url = "http://${config.mySnippets.cute-haus.networkMap.audiobookshelf.hostName}:${toString config.mySnippets.cute-haus.networkMap.audiobookshelf.port}/";
                        icon = "di:audiobookshelf";
                      }
                      {
                        title = "Immich";
                        url = "https://${config.mySnippets.cute-haus.networkMap.immich.vHost}/";
                        check-url = "http://${config.mySnippets.cute-haus.networkMap.immich.hostName}:${toString config.mySnippets.cute-haus.networkMap.immich.port}/";
                        icon = "di:immich";
                      }
                      {
                        title = "Forĝejo";
                        url = "https://${config.mySnippets.cute-haus.networkMap.forgejo.vHost}/";
                        check-url = "http://${config.mySnippets.cute-haus.networkMap.forgejo.hostName}:${toString config.mySnippets.cute-haus.networkMap.forgejo.port}/";
                        icon = "di:forgejo";
                      }
                      {
                        title = "Karakeep";
                        url = "https://${config.mySnippets.cute-haus.networkMap.karakeep.vHost}/";
                        check-url = "http://${config.mySnippets.cute-haus.networkMap.karakeep.hostName}:${toString config.mySnippets.cute-haus.networkMap.karakeep.port}/";
                        icon = "di:karakeep";
                      }
                      {
                        title = "aly.social";
                        url = "https://${config.mySnippets.cute-haus.networkMap.aly-social.vHost}/";
                        check-url = "http://${config.mySnippets.cute-haus.networkMap.aly-social.hostName}:${toString config.mySnippets.cute-haus.networkMap.aly-social.port}/";
                        icon = "di:bluesky";
                      }
                      {
                        title = "Vaultwarden";
                        url = "https://${config.mySnippets.cute-haus.networkMap.vaultwarden.vHost}/";
                        check-url = "http://${config.mySnippets.cute-haus.networkMap.vaultwarden.hostName}:${toString config.mySnippets.cute-haus.networkMap.vaultwarden.port}/";
                        icon = "di:vaultwarden";
                      }
                    ];
                  }
                  {
                    type = "monitor";
                    cache = "1m";
                    title = "Private Services";

                    sites = [
                      {
                        title = "Jellyfin";
                        url = "https://${config.mySnippets.tailnet.networkMap.jellyfin.vHost}/";
                        check-url = "http://${config.mySnippets.tailnet.networkMap.jellyfin.hostName}:${toString config.mySnippets.tailnet.networkMap.jellyfin.port}/web/index.html";
                        icon = "di:jellyfin";
                      }
                      {
                        title = "Photoprism";
                        url = "https://${config.mySnippets.tailnet.networkMap.photoprism.vHost}/";
                        check-url = "http://${config.mySnippets.tailnet.networkMap.photoprism.hostName}:${toString config.mySnippets.tailnet.networkMap.photoprism.port}";
                        icon = "di:photoprism";
                      }
                      {
                        title = "Navidrome";
                        url = "https://${config.mySnippets.tailnet.networkMap.navidrome.vHost}/";
                        check-url = "http://${config.mySnippets.tailnet.networkMap.navidrome.hostName}:${toString config.mySnippets.tailnet.networkMap.navidrome.port}/web/index.html";
                        icon = "di:navidrome";
                      }
                      {
                        title = "Sonarr";
                        url = "https://${config.mySnippets.tailnet.networkMap.sonarr.vHost}/";
                        check-url = "http://${config.mySnippets.tailnet.networkMap.sonarr.hostName}:${toString config.mySnippets.tailnet.networkMap.sonarr.port}/";
                        icon = "di:sonarr";
                      }
                      {
                        title = "Radarr";
                        url = "https://${config.mySnippets.tailnet.networkMap.radarr.vHost}/";
                        check-url = "http://${config.mySnippets.tailnet.networkMap.radarr.hostName}:${toString config.mySnippets.tailnet.networkMap.radarr.port}/";
                        icon = "di:radarr";
                      }
                      {
                        title = "Lidarr";
                        url = "https://${config.mySnippets.tailnet.networkMap.lidarr.vHost}/";
                        check-url = "http://${config.mySnippets.tailnet.networkMap.lidarr.hostName}:${toString config.mySnippets.tailnet.networkMap.lidarr.port}/";
                        icon = "di:lidarr";
                      }
                      {
                        title = "Prowlarr";
                        url = "https://${config.mySnippets.tailnet.networkMap.prowlarr.vHost}/";
                        check-url = "http://${config.mySnippets.tailnet.networkMap.prowlarr.hostName}:${toString config.mySnippets.tailnet.networkMap.prowlarr.port}/";
                        icon = "di:prowlarr";
                      }
                      {
                        title = "Bazarr";
                        url = "https://${config.mySnippets.tailnet.networkMap.bazarr.vHost}/";
                        check-url = "http://${config.mySnippets.tailnet.networkMap.bazarr.hostName}:${toString config.mySnippets.tailnet.networkMap.bazarr.port}/";
                        icon = "di:bazarr";
                      }
                      {
                        title = "Tautulli";
                        url = "https://${config.mySnippets.tailnet.networkMap.tautulli.vHost}/";
                        check-url = "http://${config.mySnippets.tailnet.networkMap.tautulli.hostName}:${toString config.mySnippets.tailnet.networkMap.tautulli.port}/";
                        icon = "di:tautulli";
                      }
                      {
                        title = "qBittorrent";
                        url = "https://${config.mySnippets.tailnet.networkMap.qbittorrent.vHost}/";
                        check-url = "http://${config.mySnippets.tailnet.networkMap.qbittorrent.hostName}:${toString config.mySnippets.tailnet.networkMap.qbittorrent.port}/";
                        icon = "di:qbittorrent";
                        alt-status-codes = [401];
                      }
                      # {
                      #   title = "Homebridge";
                      #   url = "https://homebridge.${config.mySnippets.tailnet.name}/";
                      #   icon = "di:homebridge";
                      # }
                      {
                        title = "Grafana";
                        url = "https://${config.mySnippets.tailnet.networkMap.grafana.vHost}/";
                        check-url = "http://${config.mySnippets.tailnet.networkMap.grafana.hostName}:${toString config.mySnippets.tailnet.networkMap.grafana.port}/";
                        icon = "di:grafana";
                      }
                      {
                        title = "Uptime Kuma";
                        url = "https://${config.mySnippets.tailnet.networkMap.uptime-kuma.vHost}/";
                        check-url = "http://${config.mySnippets.tailnet.networkMap.uptime-kuma.hostName}:${toString config.mySnippets.tailnet.networkMap.uptime-kuma.port}/";
                        icon = "di:uptime-kuma";
                      }
                    ];
                  }
                  {
                    type = "split-column";
                    widgets = [
                      {
                        type = "hacker-news";
                        collapse-after = 4;
                      }
                      {
                        type = "rss";
                        title = "The Verge";
                        limit = 10;
                        collapse-after = 5;
                        cache = "12h";

                        feeds = [
                          {
                            url = "https://www.theverge.com/rss/index.xml";
                            title = "The Verge";
                            limit = 4;
                          }
                        ];
                      }
                    ];
                  }
                  {
                    collapse-after-rows = 1;
                    style = "grid-cards";
                    type = "videos";

                    channels = [
                      "UCXuqSBlHAE6Xw-yeJA0Tunw" # Linus Tech Tips
                      "UCR-DXc1voovS8nhAvccRZhg" # Jeff Geerling
                      "UCHnyfMqiRRG1u-2MsSQLbXA" # Veritasium
                      "UC9PBzalIcEQCsiIkq36PyUA" # Digital Foundry
                      "UCpa-Zb0ZcQjTCPP1Dx_1M8Q" # LegalEagle
                      "UCld68syR8Wi-GY_n4CaoJGA" # Brodie Robertson
                    ];
                  }
                  {
                    type = "split-column";
                    widgets = [
                      {
                        type = "rss";
                        title = "NPR";
                        limit = 10;
                        collapse-after = 5;
                        cache = "12h";

                        feeds = [
                          {
                            url = "https://feeds.npr.org/1001/rss.xml";
                            title = "NPR";
                            limit = 4;
                          }
                        ];
                      }
                      {
                        type = "lobsters";
                        collapse-after = 4;
                      }
                    ];
                  }
                  {
                    type = "bookmarks";
                    groups = [
                      {
                        title = "Aly Raffauf";
                        links = [
                          {
                            title = "Website";
                            url = "https://aly.codes/";
                          }
                          {
                            title = "Github";
                            url = "https://github.com/alyraffauf/";
                          }
                          {
                            title = "Linkedin";
                            url = "https://www.linkedin.com/in/alyraffauf/";
                          }
                        ];
                      }
                      {
                        title = "General";
                        links = [
                          {
                            title = "Fastmail";
                            url = "https://fastmail.com/";
                          }
                          {
                            title = "YouTube";
                            url = "https://www.youtube.com/";
                          }
                          {
                            title = "Github";
                            url = "https://github.com/";
                          }
                        ];
                      }
                      {
                        title = "Social";
                        links = [
                          {
                            title = "Bluesky";
                            url = "https://bsky.app/";
                          }
                          {
                            title = "Reddit";
                            url = "https://www.reddit.com/";
                          }
                          {
                            title = "Instagram";
                            url = "https://www.instagram.com/";
                          }
                        ];
                      }
                    ];
                  }
                ];
              }
            ];
          }
        ];

        server.host = "0.0.0.0";
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
        NEXTAUTH_URL = "https://${config.mySnippets.cute-haus.networkMap.karakeep.vHost}";
        OLLAMA_BASE_URL = "https://ollama.${config.mySnippets.tailnet.name}";
        OLLAMA_KEEP_ALIVE = "5m";
        PORT = "7020";
      };
    };

    meilisearch.settings.experimental_dumpless_upgrade = true;
  };
}
