_: {
  flake.nixosModules.jubilife = {
    services.nfs.server = {
      enable = true;
      exports = ''
        /mnt/Data 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,fsid=0) 10.42.0.0/16(rw,sync,no_subtree_check,no_root_squash,fsid=0)
        /mnt/Media 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,fsid=1) 10.42.0.0/16(rw,sync,no_subtree_check,no_root_squash,fsid=1)
      '';
    };
  };
}
