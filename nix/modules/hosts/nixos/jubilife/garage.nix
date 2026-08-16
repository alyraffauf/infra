_: {
  flake.nixosModules.jubilife = {
    config,
    pkgs,
    self,
    ...
  }: let
    dataDirectory = "/mnt/Data";
  in {
    sops.secrets = {
      garageNextcloudAccessKey = {
        sopsFile = "${self}/secrets/garage.yaml";
        key = "nextcloud_access_key";
        owner = "garage";
        group = "garage";
      };
      garageNextcloudSecretKey = {
        sopsFile = "${self}/secrets/garage.yaml";
        key = "nextcloud_secret_key";
        owner = "garage";
        group = "garage";
      };
      garageRpcSecret = {
        sopsFile = "${self}/secrets/garage.yaml";
        key = "rpc_secret";
        owner = "garage";
        group = "garage";
      };
    };
    sops.templates = {
      garage-config = {
        owner = "garage";
        group = "garage";
        mode = "0400";
        content = ''
          metadata_dir = "${dataDirectory}/garage/meta"
          data_dir = "${dataDirectory}/garage/data"
          db_engine = "sqlite"
          replication_factor = 1
          rpc_bind_addr = "[::]:3901"
          rpc_public_addr = "10.254.0.1:3901"
          rpc_secret = "${config.sops.placeholder.garageRpcSecret}"

          [s3_api]
          api_bind_addr = "10.254.0.1:3900"
          s3_region = "garage"
        '';
      };
      garage-environment = {
        owner = "garage";
        group = "garage";
        mode = "0400";
        content = ''
          GARAGE_CONFIG_FILE=${config.sops.templates.garage-config.path}
          GARAGE_DEFAULT_ACCESS_KEY=${config.sops.placeholder.garageNextcloudAccessKey}
          GARAGE_DEFAULT_SECRET_KEY=${config.sops.placeholder.garageNextcloudSecretKey}
          GARAGE_DEFAULT_BUCKET=aly-nextcloud
        '';
      };
    };
    users = {
      groups.garage = {};
      users.garage = {
        isSystemUser = true;
        group = "garage";
      };
    };
    services.garage = {
      enable = true;
      package = pkgs.garage_2;
      environmentFile = config.sops.templates.garage-environment.path;
      settings = {
        metadata_dir = "${dataDirectory}/garage/meta";
        data_dir = "${dataDirectory}/garage/data";
      };
    };
    systemd.services.garage = {
      after = ["mnt-Data.mount"];
      requires = ["mnt-Data.mount"];
      serviceConfig = {
        DynamicUser = false;
        User = "garage";
        Group = "garage";
      };
    };
  };
}
