{
  config,
  lib,
  ...
}: {
  options.myNixOs.program.docker.enable = lib.mkEnableOption "Docker container runtime";

  config = lib.mkIf config.myNixOs.program.docker.enable {
    virtualisation.oci-containers.backend = "docker";

    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };
  };
}
