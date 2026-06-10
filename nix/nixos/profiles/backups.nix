{self, ...}: {
  flake.modules.nixos.backups = {
    config,
    lib,
    ...
  }: let
    backupDestination = "rclone:b2:aly-backups/${config.networking.hostName}";
    mkRepo = service: "${backupDestination}/${service}";

    restic = {
      extraBackupArgs = [
        "--cleanup-cache"
        "--compression max"
        "--no-scan"
      ];

      inhibitsSleep = true;
      initialize = true;
      passwordFile = config.sops.secrets.restic-passwd.path;

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];

      rcloneConfigFile = config.sops.secrets.rclone-b2.path;

      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "3h";
      };
    };
  in {
    options.myBackups.jobs = lib.mkOption {
      description = "Restic backup jobs rendered with the shared defaults.";
      default = {};

      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          paths = lib.mkOption {
            type = lib.types.listOf lib.types.path;
            description = "Paths to back up.";
          };

          repository = lib.mkOption {
            type = lib.types.str;
            default = mkRepo name;
            description = "Restic repository URL.";
          };

          backupPrepareCommand = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };

          backupCleanupCommand = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };

          exclude = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
        };
      }));
    };

    config = {
      sops.secrets = {
        restic-passwd = {
          sopsFile = "${self}/secrets/restic.yaml";
          key = "PASSWORD";
        };

        rclone-b2 = {
          sopsFile = "${self}/secrets/b2.yaml";
          key = "rclone_config";
        };
      };

      services.restic.backups = lib.mapAttrs (_: job:
        restic
        // {
          inherit (job) paths repository exclude;
          backupPrepareCommand = lib.mkIf (job.backupPrepareCommand != null) job.backupPrepareCommand;
          backupCleanupCommand = lib.mkIf (job.backupCleanupCommand != null) job.backupCleanupCommand;
        })
      config.myBackups.jobs;
    };
  };
}
