{
  config,
  lib,
  ...
}: {
  options.myNixOs.service.cachefilesd.enable = lib.mkEnableOption "cachefilesd";

  config = lib.mkIf config.myNixOs.service.cachefilesd.enable {
    services.cachefilesd = {
      enable = true;

      extraConfig = ''
        brun 20%
        bcull 10%
        bstop 5%
      '';
    };
  };
}
