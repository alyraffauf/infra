{
  config,
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.pastoria = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      alloy
      backups
      base
      fail2ban
      k3s-node
      locale-en-us
      podman
      prometheus-node
      ssh-keys
      swap
      tailscale
      users
      vps

      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      config.flake.diskoConfigurations.lvm-ext4
      (
        {modulesPath, ...}: {
          imports = [
            "${modulesPath}/profiles/qemu-guest.nix"
          ];

          boot.loader.grub = {
            efiSupport = true;
            efiInstallAsRemovable = true;
          };

          networking.hostName = "pastoria";
          nixpkgs.hostPlatform = "x86_64-linux";
          system.stateVersion = "26.05";
          myDisko.installDrive = "/dev/sda";
          system.autoUpgrade.dates = "01:45";

          myK3s = {
            role = "server";
            serverAddr = "https://solaceon:6443";
            zone = "cloud-ovhcloud";
            ingress = true;
          };

          mySwap.size = 4096;
        }
      )

      {
        nixpkgs = {
          overlays = [self.overlays.default];
          config.allowUnfree = true;
        };
      }
    ];
  };
}
