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
            firewall.allowedTCPPorts = [23];
            hostName = "pastoria";
          };

          nixpkgs.hostPlatform = "x86_64-linux";
          system.stateVersion = "26.05";
          myDisko.installDrive = "/dev/sda";
          system.autoUpgrade.dates = "01:45";

          systemd.services.atbbs-telnet = {
            description = "TCP proxy for atbbs telnet";
            wantedBy = ["multi-user.target"];
            after = ["network.target"];

            serviceConfig = {
              ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:23,fork,reuseaddr TCP:eterna:2323";
              Restart = "always";
            };
          };

          myK3s = {
            role = "server";
            serverAddr = "https://snowpoint:6443";
            zone = "cloud";
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
