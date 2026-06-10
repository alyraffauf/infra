_: {
  flake.modules.nixos.framework-13 = {
    config,
    lib,
    pkgs,
    ...
  }: {
    boot = {
      extraModulePackages = with config.boot.kernelPackages; [
        framework-laptop-kmod
      ];

      kernelModules = [
        "cros_ec_lpcs"
        "cros_ec"
      ];
    };

    environment.systemPackages = [pkgs.framework-tool] ++ lib.optional (pkgs ? "fw-ectool") pkgs.fw-ectool;

    hardware.sensor.iio.enable = true;

    services = {
      fprintd.enable = true;
      fwupd.enable = true;

      udev.extraRules = ''
        ## Framework ethernet expansion card support
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", ATTR{power/autosuspend}="20"
      '';
    };
  };
}
