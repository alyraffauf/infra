{self, ...}: {
  flake.nynxDeployments = {
    eterna.output = self.nixosConfigurations.eterna.config.system.build.toplevel;
    eterna.user = "root";

    jubilife.output = self.nixosConfigurations.jubilife.config.system.build.toplevel;
    jubilife.user = "root";

    pastoria.output = self.nixosConfigurations.pastoria.config.system.build.toplevel;
    pastoria.user = "root";

    snowpoint.output = self.nixosConfigurations.snowpoint.config.system.build.toplevel;
    snowpoint.user = "root";
  };
}
