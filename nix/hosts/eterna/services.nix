_: let
  tnet = "narwhal-snapper.ts.net";
in {
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
}
