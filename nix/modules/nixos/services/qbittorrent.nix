_: {
  flake.nixosModules.qbittorrent = {
    config,
    pkgs,
    ...
  }: {
    services.qbittorrent = {
      enable = true;
      profileDir = "/var/lib/qbittorrent";
    };

    myNixOs.profile.backups.jobs.qbittorrent = let
      stop = service: "${pkgs.systemd}/bin/systemctl stop ${service}";
      start = service: "${pkgs.systemd}/bin/systemctl start ${service}";
    in {
      backupCleanupCommand = start "qbittorrent";
      backupPrepareCommand = stop "qbittorrent";
      paths = [config.services.qbittorrent.profileDir];
    };
  };
}
