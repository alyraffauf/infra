{
  inputs,
  self,
  ...
}: {
  config.flake.nixosConfigurations.jubilife = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs self;};
    modules = [
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      self.nixosModules.default
      self.nixosModules.jubilife
      self.nixosModules.intelGpu
      self.nixosModules.disko
      self.nixosModules.luksBtrfsSubvolumes
      self.nixosModules.arr
      self.nixosModules.b2Mounts
      self.nixosModules.backups
      self.nixosModules.btrfs
      self.nixosModules.k3s
      self.nixosModules.swap
      self.nixosModules.wireguardK3s
      self.nixosModules.lanzaboote
      self.nixosModules.docker
      self.nixosModules.dockerNetworks
      self.nixosModules.alloy
      self.nixosModules.atbbs
      self.nixosModules.caddy
      self.nixosModules.fail2ban
      self.nixosModules.tautulli
      self.nixosModules.prometheusNode
      self.nixosModules.qbittorrent
      self.nixosModules.syncthing
      self.nixosModules.tailscale
      self.nixosModules.aly
    ];
  };
}
