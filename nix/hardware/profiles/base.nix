_: {
  flake.modules.nixos.hw-base = {
    hardware.enableAllFirmware = true;
    services.fstrim.enable = true;
  };
}
