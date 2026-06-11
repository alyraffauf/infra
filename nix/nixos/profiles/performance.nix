{
  flake.modules.nixos.performance = {lib, ...}: {
    boot.kernel.sysctl = {
      "fs.file-max" = lib.mkDefault 2097152;
      "fs.inotify.max_user_instances" = lib.mkOverride 100 8192;
      "fs.inotify.max_user_watches" = lib.mkOverride 100 524288;
    };

    hardware.block = {
      defaultScheduler = "kyber";
      defaultSchedulerRotational = "bfq";

      scheduler = {
        "mmcblk[0-9]*" = "bfq";
        "nvme[0-9]*" = "kyber";
      };
    };

    services.bpftune.enable = true;

    systemd.oomd = {
      enable = true;
      enableRootSlice = true;
      enableSystemSlice = true;
      enableUserSlices = true;
    };
  };
}
