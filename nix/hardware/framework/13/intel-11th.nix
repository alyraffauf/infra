_: {
  flake.modules.nixos.framework-13-intel-11th = {
    lib,
    pkgs,
    ...
  }: {
    boot = {
      blacklistedKernelModules = ["cros-usbpd-charger"];
      initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod"];
      kernelPackages = lib.mkIf (lib.versionOlder pkgs.linux.version "6.11") (lib.mkDefault pkgs.linuxPackages_latest);

      kernelParams = [
        "nvme.noacpi=1"
      ];
    };

    hardware.acpilight.enable = true;
    powerManagement.powertop.enable = lib.mkForce false;

    services.udev.extraRules = ''
      ## Framework 13 -- Fix headphone noise when on powersave
      ## https://community.frame.work/t/headphone-jack-intermittent-noise/5246/55
      SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0xa0e0", ATTR{power/control}="on"
    '';
  };
}
