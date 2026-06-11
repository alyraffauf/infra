{
  flake.modules.nixos.btrfs = {
    config,
    lib,
    pkgs,
    ...
  }: let
    btrfsFSDevices = let
      isDeviceInList = list: device: builtins.any (e: e.device == device) list;
      uniqueDeviceList = lib.foldl' (acc: e:
        if isDeviceInList acc e.device
        then acc
        else acc ++ [e]) [];
    in
      uniqueDeviceList (
        lib.mapAttrsToList (_: fs: {inherit (fs) mountPoint device;})
        (lib.filterAttrs (_: fs: fs.fsType == "btrfs") config.fileSystems)
      );

    beesdConfig = lib.listToAttrs (map (fs: {
        name = lib.strings.sanitizeDerivationName (baseNameOf fs.device);
        value = {
          hashTableSizeMB = 2048;
          spec = fs.device;
          verbosity = "info";
          extraOptions = ["--loadavg-target" "1.0" "--thread-factor" "0.50"];
        };
      })
      btrfsFSDevices);

    hasHomeSubvolume =
      lib.hasAttr "/home" config.fileSystems
      && config.fileSystems."/home".fsType == "btrfs";
  in {
    options.myBtrfs.deduplicate = lib.mkEnableOption "deduplicate btrfs filesystems";

    config = {
      boot.supportedFilesystems = ["btrfs"];
      environment.systemPackages = lib.optionals config.services.xserver.enable [pkgs.snapper-gui];

      services = lib.mkIf (btrfsFSDevices != []) {
        beesd.filesystems = lib.mkIf config.myBtrfs.deduplicate beesdConfig;
        btrfs.autoScrub.enable = true;

        snapper = {
          configs.home = lib.mkIf hasHomeSubvolume {
            ALLOW_GROUPS = ["users"];
            FSTYPE = "btrfs";
            SUBVOLUME = "/home";
            TIMELINE_CLEANUP = true;
            TIMELINE_CREATE = true;
          };

          filters = ''
            -.bash_profile
            -.bashrc
            -.cache
            -.config
            -.librewolf
            -.local
            -.mozilla
            -.nix-profile
            -.pki
            -.share
            -.snapshots
            -.thunderbird
            -.zshrc
          '';

          persistentTimer = true;
        };
      };
    };
  };
}
