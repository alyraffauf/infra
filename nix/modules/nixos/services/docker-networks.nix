_: {
  flake.nixosModules.dockerNetworks = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) concatMapStringsSep escapeShellArg filterAttrs listToAttrs mapAttrs' mkOption nameValuePair optionals types;

    networks = config.myNixOs.docker.networks;

    mkNetworkService = name: network: let
      networkArguments =
        optionals (network.subnet != null) ["--subnet" network.subnet]
        ++ optionals (network.bridgeInterface != null) ["--opt" "com.docker.network.bridge.name=${network.bridgeInterface}"];
      containerServices = map (container: "docker-${container}.service") network.containers;
    in
      nameValuePair "docker-network-${name}" {
        after = ["docker.service"];
        requires = ["docker.service"];
        before = containerServices;
        requiredBy = containerServices;

        path = [pkgs.docker];
        script = ''
          docker network inspect ${escapeShellArg name} >/dev/null 2>&1 || \
            docker network create --driver bridge ${concatMapStringsSep " " escapeShellArg networkArguments} ${escapeShellArg name}
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

    networksWithFirewall = filterAttrs (_: network: network.bridgeInterface != null && network.allowedTCPPorts != []) networks;
  in {
    options.myNixOs.docker.networks = mkOption {
      default = {};
      description = "Private Docker networks managed with their dependent containers.";
      type = types.attrsOf (types.submodule {
        options = {
          containers = mkOption {
            type = types.listOf types.str;
            description = "Containers that require this network.";
          };
          subnet = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Optional IPv4 subnet for a stable network gateway.";
          };
          bridgeInterface = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Optional Linux bridge interface name.";
          };
          allowedTCPPorts = mkOption {
            type = types.listOf types.port;
            default = [];
            description = "TCP ports exposed to containers through the bridge.";
          };
        };
      });
    };

    config = {
      networking.firewall.interfaces = listToAttrs (map (
        network: nameValuePair network.bridgeInterface {inherit (network) allowedTCPPorts;}
      ) (builtins.attrValues networksWithFirewall));

      systemd.services = mapAttrs' mkNetworkService networks;
    };
  };
}
