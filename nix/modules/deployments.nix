{self, ...}: {
  blzrd.nodes = {
    eterna = {
      output = self.nixosConfigurations.eterna.config.system.build.toplevel;
      type = "nixos";
      user = "root";
    };

    jubilife = {
      output = self.nixosConfigurations.jubilife.config.system.build.toplevel;
      type = "nixos";
      user = "root";
    };

    pastoria = {
      output = self.nixosConfigurations.pastoria.config.system.build.toplevel;
      type = "nixos";
      user = "root";
    };

    snowpoint = {
      output = self.nixosConfigurations.snowpoint.config.system.build.toplevel;
      type = "nixos";
      user = "root";
    };
  };
}
