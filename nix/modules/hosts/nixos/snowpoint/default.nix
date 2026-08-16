{
  inputs,
  self,
  ...
}: {
  config.flake.nixosConfigurations.snowpoint = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs self;};
    modules = [
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      self.nixosModules.default
      self.nixosModules.snowpoint
      self.nixosModules.disko
      self.nixosModules.lvmExt4
      self.nixosModules.backups
      self.nixosModules.dataShare
      self.nixosModules.k3s
      self.nixosModules.mediaShare
      self.nixosModules.observability
      self.nixosModules.swap
      self.nixosModules.wireguardK3s
      self.nixosModules.alloy
      self.nixosModules.cachefilesd
      self.nixosModules.caddy
      self.nixosModules.fail2ban
      self.nixosModules.prometheusNode
      self.nixosModules.syncthing
      self.nixosModules.tailscale
      self.nixosModules.aly
    ];
  };
}
