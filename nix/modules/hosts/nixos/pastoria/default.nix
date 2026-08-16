{
  inputs,
  self,
  ...
}: {
  config.flake.nixosConfigurations.pastoria = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs self;};
    modules = [
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      self.nixosModules.default
      self.nixosModules.pastoria
      self.nixosModules.disko
      self.nixosModules.lvmExt4
      self.nixosModules.backups
      self.nixosModules.k3s
      self.nixosModules.swap
      self.nixosModules.wireguardK3s
      self.nixosModules.docker
      self.nixosModules.alloy
      self.nixosModules.fail2ban
      self.nixosModules.prometheusNode
      self.nixosModules.tailscale
    ];
  };
}
