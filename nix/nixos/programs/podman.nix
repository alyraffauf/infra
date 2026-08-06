{
  config,
  lib,
  ...
}: {
  options.myNixOs.program.podman.enable = lib.mkEnableOption "podman container runtime";

  config = lib.mkIf config.myNixOs.program.podman.enable {
    virtualisation.oci-containers.backend = "podman";

    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      defaultNetwork.settings.dns_enabled = true;
      dockerCompat = true;
    };
  };
}
