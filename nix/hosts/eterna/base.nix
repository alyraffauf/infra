_: {
  myHw = {
    intel.cpu.enable = true;
    intel.gpu.enable = true;
  };

  myNixOs = {
    profile = {
      base.enable = true;
      backups.enable = true;
      btrfs.enable = true;
      dataShare.enable = true;
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
      syncthing.enable = true;
      tailscale.enable = true;
    };
    users.aly.enable = true;
  };
}
