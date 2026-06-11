{
  config,
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.solaceon = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      alloy
      backups
      base
      fail2ban
      k3s-node
      locale-en-us
      podman
      prometheus-node
      swap
      tailscale
      vps

      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      config.flake.diskoConfigurations.lvm-ext4
      (
        {
          modulesPath,
          pkgs,
          ...
        }: {
          imports = [
            "${modulesPath}/profiles/qemu-guest.nix"
          ];

          boot.loader.grub = {
            efiSupport = true;
            efiInstallAsRemovable = true;
          };

          networking = {
            firewall.allowedTCPPorts = [23 8282 8383];
            hostName = "solaceon";
          };

          systemd.services.atbbs-telnet = {
            description = "TCP proxy for atbbs telnet";
            wantedBy = ["multi-user.target"];
            after = ["network.target"];

            serviceConfig = {
              ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:23,fork,reuseaddr TCP:eterna:2323";
              Restart = "always";
            };
          };

          nixpkgs.hostPlatform = "x86_64-linux";
          system.stateVersion = "25.11";
          time.timeZone = "America/New_York";
          myDisko.installDrive = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_62292463";

          system.autoUpgrade.dates = "02:00";

          myK3s = {
            role = "server";
            clusterInit = true;
            zone = "cloud-hetzner";
            ingress = true;
          };

          mySwap.size = 2048;
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
