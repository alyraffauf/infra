{
  config,
  lib,
  ...
}: {
  options.myNixOS.profiles.zram.enable = lib.mkEnableOption "zram swap";

  config = lib.mkIf config.myNixOS.profiles.zram.enable {
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      priority = 100;
    };
  };
}
