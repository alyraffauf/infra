{
  sops.secrets = {
    k3s = {
      sopsFile = ../../secrets/k3s.yaml;
      key = "TOKEN";
    };
    rclone-b2 = {
      sopsFile = ../../secrets/b2.yaml;
      key = "rclone_config";
    };
    restic-passwd = {
      sopsFile = ../../secrets/restic.yaml;
      key = "PASSWORD";
    };
    syncthingCert = {
      sopsFile = ../../secrets/syncthing.yaml;
      key = "eterna_cert";
    };
    syncthingKey = {
      sopsFile = ../../secrets/syncthing.yaml;
      key = "eterna_key";
    };
    tailscaleAuthKey = {
      sopsFile = ../../secrets/tailscale.yaml;
      key = "auth_key";
    };
  };
}
