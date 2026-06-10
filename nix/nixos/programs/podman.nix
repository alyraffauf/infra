_: {
  flake.modules.nixos.podman = {
    config,
    lib,
    pkgs,
    ...
  }: {
    environment.systemPackages = lib.optionals config.services.xserver.enable [pkgs.pods];

    virtualisation = {
      oci-containers.backend = "podman";

      podman = {
        enable = true;
        autoPrune.enable = true;
        defaultNetwork.settings.dns_enabled = true;
        dockerCompat = true;
      };
    };
  };
}
