{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.myNixOs.profile.base.enable {
    environment.systemPackages = with pkgs; [
      (inxi.override {withRecommends = true;})
      helix
      lm_sensors
      python314
      rclone
      wget
      zellij
    ];
  };
}
