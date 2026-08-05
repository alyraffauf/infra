{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.myNixOs.profile.base.enable {
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      priority = 100;
    };
  };
}
