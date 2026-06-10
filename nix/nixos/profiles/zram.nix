_: {
  flake.modules.nixos.zram = {
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      priority = 100;
    };
  };
}
