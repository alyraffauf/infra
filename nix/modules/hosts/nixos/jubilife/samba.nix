_: {
  flake.nixosModules.jubilife = {config, ...}: {
    services = {
      samba = {
        enable = true;
        openFirewall = true;
        settings = {
          global = {
            security = "user";
            "map to guest" = "Bad User";
            "server min protocol" = "SMB3";
            "server max protocol" = "SMB3_11";
            "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=262144 SO_SNDBUF=262144";
            "use sendfile" = "no";
            "aio read size" = "1";
            "aio write size" = "1";
            "min receivefile size" = "131072";
            "max xmit" = "65535";
            "strict locking" = "no";
            oplocks = "yes";
            "level2 oplocks" = "yes";
          };
          Data = {
            "create mask" = "0755";
            "directory mask" = "0755";
            "force group" = "users";
            "force user" = "aly";
            "guest ok" = "yes";
            "read only" = "no";
            browseable = "yes";
            comment = "Data @ ${config.networking.hostName}";
            path = "/mnt/Data";
          };
          Media = {
            "create mask" = "0755";
            "directory mask" = "0755";
            "force group" = "users";
            "force user" = "aly";
            "guest ok" = "yes";
            "read only" = "no";
            browseable = "yes";
            comment = "Media @ ${config.networking.hostName}";
            path = "/mnt/Media";
          };
        };
      };
      samba-wsdd = {
        enable = true;
        openFirewall = true;
      };
    };
  };
}
