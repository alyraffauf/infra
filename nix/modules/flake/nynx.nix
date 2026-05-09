{self, ...}: {
  flake.nynxDeployments = {
    celestic.output = self.nixosConfigurations.celestic.config.system.build.toplevel;
    celestic.user = "root";

    eterna.output = self.nixosConfigurations.eterna.config.system.build.toplevel;
    eterna.user = "root";

    jubilife.output = self.nixosConfigurations.jubilife.config.system.build.toplevel;
    jubilife.user = "root";

    snowpoint.output = self.nixosConfigurations.snowpoint.config.system.build.toplevel;
    snowpoint.user = "root";

    solaceon.output = self.nixosConfigurations.solaceon.config.system.build.toplevel;
    solaceon.user = "root";
  };
}
