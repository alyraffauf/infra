{
  ...
}: {
  myHw = {
    amd.cpu.enable = true;
    intel.gpu.enable = true;
  };

  myNixOs = {
    profile = {
      arr.enable = true;
      b2Mounts.enable = true;
      backups.enable = true;
      base.enable = true;
      btrfs.enable = true;
      k3s.enable = true;
      localeEnUs.enable = true;
      swap.enable = true;
      vps.enable = true;
      wireguardK3s.enable = true;
    };
    program = {
      lanzaboote.enable = true;
      docker.enable = true;
    };
    service = {
      alloy.enable = true;
      caddy.enable = true;
      fail2ban.enable = true;
      prometheusNode.enable = true;
      qbittorrent.enable = true;
      syncthing.enable = true;
      tailscale.enable = true;
      tautulli.enable = true;
    };
    users.aly.enable = true;
  };

  myDisko.profile.luksBtrfsSubvolumes.enable = true;
}
