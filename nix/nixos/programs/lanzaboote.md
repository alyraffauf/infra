# Secure Boot + Automatic LUKS decryption

1. Generate secure boot keys:

   ```bash
   sudo nix run nixpkgs#sbctl create-keys
   ```

1. Include `nixos-programs-lanzaboote` or manually enable lanzaboote in NixOS host configuration:

   ```nix
   boot = {
     initrd.systemd.enable = true; # For automatic decryption with TPM.
     loader.systemd-boot.enable = lib.mkForce false; # Interferes with lanzaboote and must be force-disabled.

     lanzaboote = {
       enable = true;
       pkiBundle = "/var/lib/sbctl";
     };
   };
   ```

1. In UEFI, set secure boot to "setup mode" or erase platform keys.

1. Enroll your secure boot keys:

   ```bash
   sudo nix run nixpkgs#sbctl -- enroll-keys --microsoft
   ```

1. Reboot, make sure secure boot is enabled in UEFI.

1. Check secure boot status with `bootctl status`:

   ```bash
   System:
         Firmware: UEFI 2.70 (American Megatrends 5.17)
   Firmware Arch: x64
     Secure Boot: enabled (user)
     TPM2 Support: yes
     Measured UKI: yes
     Boot into FW: supported
   ```

1. If your root drive is encrypted with LUKS, you can have the TPM automatically decrypt it on boot:

   ```bash
   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7+12 --wipe-slot=tpm2 /dev/nvme0n1p2
   ```

   Replace `/dev/nvme0n1p2` with your root partition. This policy binds the LUKS key to:
   - PCR 0: core platform firmware;
   - PCR 2: UEFI drivers and option ROMs loaded by the firmware;
   - PCR 7: the Secure Boot state and trust policy;
   - PCR 12: initrd global credentials and other boot configuration measured by the platform.

   PCR measurements are platform-dependent. Firmware or device changes can affect PCRs 0 and 2, Secure Boot key or policy changes can affect PCR 7, and NixOS or systemd updates that alter initrd global credentials can affect PCR 12. If any selected PCR differs, automatic unlock fails and the system falls back to the LUKS recovery passphrase. Always retain and test a recovery passphrase, especially on unattended systems.

   PCR 4 measures the bootloader and selected Lanzaboote EFI image. It provides stronger binding to a specific boot image, but its literal value changes when a new image is installed. Do not add PCR 4 to a static `systemd-cryptenroll --tpm2-pcrs=` policy if boot-image updates must remain unattended; managing multiple approved boot measurements requires a managed PCR policy.

   Check the [Linux TPM PCR Registry](https://uapi-group.org/specifications/specs/linux_tpm_pcr_registry/) for more details.

   **NOTE:** This requires a TPM2 module; devices with prior TPM versions will not work.
