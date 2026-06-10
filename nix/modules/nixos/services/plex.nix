{
  config,
  lib,
  self,
  ...
}: {
  options.myNixOS.services.plex = {
    enable = lib.mkEnableOption "plex media server";

    dataDir = lib.mkOption {
      description = "Data directory to use.";
      default = "/var/lib";
      type = lib.types.str;
    };

    tautulli.enable = lib.mkEnableOption "tautulli";
  };

  config = lib.mkMerge [
    (lib.mkIf config.myNixOS.services.plex.enable {
      services.plex = {
        enable = true;
        dataDir = "${config.myNixOS.services.plex.dataDir}/plex";

        extraPlugins = [
          (builtins.path {
            name = "Audnexus.bundle";
            path = self.inputs.audnexus;
          })
          (builtins.path {
            name = "Hama.bundle";
            path = self.inputs.hama;
          })
        ];

        extraScanners = [
          (builtins.path {
            name = "Absolute-Series-Scanner";
            path = self.inputs.absolute;
          })
        ];

        openFirewall = true;
      };

      # Plex's main process exits on SIGTERM but leaves transcoder children
      # alive in the cgroup, so systemd waits the full default 90s before
      # SIGKILL on every shutdown. Cap to 15s — the cache regenerates.
      systemd.services.plex.serviceConfig.TimeoutStopSec = 15;
    })

    (lib.mkIf config.myNixOS.services.plex.tautulli.enable {
      services.tautulli = {
        enable = true;
        openFirewall = true;
      };
    })
  ];
}
