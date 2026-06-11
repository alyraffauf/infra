{
  flake.modules.nixos.alloy = {
    config,
    lib,
    ...
  }: {
    options.myAlloy.lokiUrl = lib.mkOption {
      description = "Loki URL to report to";
      default = "https://loki.narwhal-snapper.ts.net/loki/api/v1/push";
      type = lib.types.str;
    };

    config = {
      services.alloy.enable = true;

      environment.etc."alloy/config.alloy".text = ''
        loki.write "default" {
          endpoint {
            url = "${config.myAlloy.lokiUrl}"
          }
        }

        loki.relabel "journal" {
          forward_to = []

          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
          }

          rule {
            source_labels = ["__journal__systemd_user_unit"]
            target_label  = "user_unit"
          }
        }

        loki.source.journal "read" {
          forward_to    = [loki.write.default.receiver]
          relabel_rules = loki.relabel.journal.rules
          max_age       = "12h"
          labels        = {
            job  = "systemd-journal",
            host = "${config.networking.hostName}",
          }
        }
      '';
    };
  };
}
