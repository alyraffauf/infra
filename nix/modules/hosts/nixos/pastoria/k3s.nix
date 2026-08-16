_: {
  flake.nixosModules.pastoria = {
    myNixOs.profile = {
      k3s = {
        role = "server";
        serverAddr = "https://snowpoint.cute:6443";
        transportInterface = "wg-k3s";
        nodeIP = "10.254.0.2";
        zone = "cloud";
        ingress = true;
      };
      swap.size = 4096;
    };
  };
}
