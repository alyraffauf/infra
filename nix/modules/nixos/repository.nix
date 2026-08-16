_: {
  flake.nixosModules.default = {self, ...}: {
    environment.etc."nixos".source = self;
    system.configurationRevision = self.rev or self.dirtyRev or null;
  };
}
