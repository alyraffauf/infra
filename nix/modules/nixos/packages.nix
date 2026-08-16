_: {
  flake.nixosModules.default = {pkgs, ...}: {
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
