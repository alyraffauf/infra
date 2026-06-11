{
  flake.modules.nixos.media-share = {
    config,
    pkgs,
    ...
  }: {
    assertions = [
      {
        assertion = config.services.tailscale.enable;
        message = "NFS connects to jubilife shares over tailscale, but services.tailscale.enable != true.";
      }
    ];

    environment.systemPackages = [pkgs.nfs-utils];

    fileSystems."/mnt/Media" = {
      fsType = "nfs";
      device = "jubilife:/mnt/Media";

      options = [
        "default"
        "noatime"
        "nofail"
        "retrans=2"
        "rsize=1048576"
        "wsize=1048576"
        "x-systemd.after=network-online.target"
        "x-systemd.after=tailscaled.service"
        "x-systemd.automount"
        "x-systemd.device-timeout=5s"
        "x-systemd.idle-timeout=60"
        "x-systemd.mount-timeout=5s"
      ];
    };
  };
}
