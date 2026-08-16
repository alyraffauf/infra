{
  inputs,
  self,
  ...
}: {
  config.flake.nixosConfigurations.eterna = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs self;};
    modules = [
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      self.nixosModules.default
      self.nixosModules.eterna
      self.nixosModules.intelGpu
      self.nixosModules.backups
      self.nixosModules.btrfs
      self.nixosModules.dataShare
      self.nixosModules.swap
      self.nixosModules.wireguardK3s
      self.nixosModules.lanzaboote
      self.nixosModules.docker
      self.nixosModules.alloy
      self.nixosModules.caddy
      self.nixosModules.fail2ban
      self.nixosModules.prometheusNode
      self.nixosModules.syncthing
      self.nixosModules.tailscale
      self.nixosModules.aly
    ];
  };
}
