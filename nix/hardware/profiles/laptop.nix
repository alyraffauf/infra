_: {
  flake.modules.nixos.hw-laptop = {
    config,
    lib,
    ...
  }: {
    boot.kernel.sysctl."kernel.nmi_watchdog" = lib.mkDefault 0;

    services = {
      tuned = {
        enable = lib.mkDefault true;
        settings.dynamic_tuning = true;
      };

      upower.enable = true;

      thermald.enable = lib.mkIf (lib.elem "kvm-intel" config.boot.kernelModules) true;
    };

    hardware.nvidia = lib.mkIf (lib.elem "nvidia" config.services.xserver.videoDrivers) {
      dynamicBoost.enable = lib.mkDefault true;

      powerManagement = {
        enable = true;
        finegrained = true;
      };

      prime.offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };

    specialisation = lib.mkIf (lib.elem "nvidia" config.services.xserver.videoDrivers) {
      nvidia-sync.configuration = {
        environment.etc."specialisation".text = "nvidia-sync";

        hardware.nvidia = {
          powerManagement = {
            enable = lib.mkForce false;
            finegrained = lib.mkForce false;
          };

          prime = {
            offload = {
              enable = lib.mkForce false;
              enableOffloadCmd = lib.mkForce false;
            };

            sync.enable = lib.mkForce true;
          };
        };
      };
    };
  };
}
