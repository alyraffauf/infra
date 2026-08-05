{
  config,
  lib,
  pkgs,
  ...
}: {
  options.myNixOs.service.qbittorrent.enable = lib.mkEnableOption "qBittorrent";

  config = lib.mkMerge [
    (lib.mkIf config.myNixOs.service.qbittorrent.enable {
      services.qbittorrent = {
        enable = true;
        profileDir = "/var/lib/qbittorrent";
      };
    })

    (lib.mkIf (config.myNixOs.service.qbittorrent.enable && config.myNixOs.profile.backups.enable) (let
      stop = service: "${pkgs.systemd}/bin/systemctl stop ${service}";
      start = service: "${pkgs.systemd}/bin/systemctl start ${service}";
    in {
      myNixOs.profile.backups.jobs.qbittorrent = {
        backupCleanupCommand = start "qbittorrent";
        backupPrepareCommand = stop "qbittorrent";
        paths = [config.services.qbittorrent.profileDir];
      };
    }))
  ];
}
