_: {
  flake.nixosModules.jubilife = {
    myNixOs.profile.k3s = {
      role = "server";
      clusterInit = true;
      transportInterface = "wg-k3s";
      nodeIP = "10.254.0.1";
      zone = "home";
    };
  };
}
