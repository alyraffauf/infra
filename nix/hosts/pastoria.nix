{
  config,
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.pastoria = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      fail2ban
      flake-url
      known-hosts
      locale-en-us
      njust
      recipes
      performance
      ssh-keys
      users
      alloy
      auto-upgrade
      backups
      k3s-node
      nix-config
      podman
      prometheus-node
      swap
      tailscale
      vps
      zram

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
          myAutoUpgrade.dates = "01:45";

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
