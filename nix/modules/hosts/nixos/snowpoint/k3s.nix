_: {
  flake.nixosModules.snowpoint = {
    myNixOs.profile.k3s = {
      role = "server";
      serverAddr = "https://pastoria.cute:6443";
      transportInterface = "wg-k3s";
      nodeIP = "10.254.0.3";
      zone = "cloud";
      ingress = true;
    };
  };
}
