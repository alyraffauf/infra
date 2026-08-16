_: {
  flake.nixosModules.jubilife = {
    config,
    self,
    ...
  }: {
    myNixOs = {
      service.syncthing = {
        certFile = config.sops.secrets.syncthingCert.path;
        keyFile = config.sops.secrets.syncthingKey.path;
        romsPath = "/mnt/Data/syncthing/ROMs";
        syncROMs = true;
        user = "aly";
      };
      users.aly.password = "$6$JTk2qi27OpA2fOAY$ZgTDg0wbmbwHUD..0xT4xYX.AR5hWQFCMVmn8G88yi3IAY7015AupovTpfy0arkI7nl/IDu5L09bzLKeXGvJC1";
    };
    sops.secrets = {
      syncthingCert = {
        sopsFile = "${self}/secrets/syncthing.yaml";
        key = "jubilife_cert";
      };
      syncthingKey = {
        sopsFile = "${self}/secrets/syncthing.yaml";
        key = "jubilife_key";
      };
    };
  };
}
