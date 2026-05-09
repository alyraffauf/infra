{
  sops.secrets = {
    k3s = {
      sopsFile = ../../../secrets/k3s.yaml;
      key = "TOKEN";
    };
    navidrome = {
      sopsFile = ../../../secrets/navidrome.yaml;
      key = "env";
    };
    rclone-b2 = {
      sopsFile = ../../../secrets/b2.yaml;
      key = "rclone_config";
    };
    restic-passwd = {
      sopsFile = ../../../secrets/restic.yaml;
      key = "PASSWORD";
    };
    syncthingCert = {
      sopsFile = ../../../secrets/syncthing.yaml;
      key = "snowpoint_cert";
    };
    syncthingKey = {
      sopsFile = ../../../secrets/syncthing.yaml;
      key = "snowpoint_key";
    };
    tailscaleAuthKey = {
      sopsFile = ../../../secrets/tailscale.yaml;
      key = "auth_key";
    };
  };
}
