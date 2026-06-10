_: {
  flake.modules.nixos.syncthing = {
    config,
    lib,
    ...
  }: {
    options.mySyncthing = {
      certFile = lib.mkOption {
        description = "Path to the certificate file.";
        type = lib.types.path;
      };

      keyFile = lib.mkOption {
        description = "Path to the key file.";
        type = lib.types.path;
      };

      romsPath = lib.mkOption {
        default = "/home/${config.mySyncthing.user}/roms";
        description = "Path to the ROM folder.";
        type = lib.types.path;
      };

      syncROMs = lib.mkEnableOption "Whether to sync ROMs.";

      user = lib.mkOption {
        description = "User to run Syncthing as.";
        type = lib.types.str;
      };
    };

    config = {
      systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";

      services = {
        caddy.virtualHosts =
          lib.mkIf
          (config.services.caddy.enable && config.services.tailscale.enable)
          {
            "syncthing-${config.networking.hostName}.narwhal-snapper.ts.net" = {
              extraConfig = ''
                bind tailscale/syncthing-${config.networking.hostName}
                reverse_proxy localhost:8384 {
                  header_up Host localhost
                }
              '';
            };
          };

        syncthing = let
          cfg = config.mySyncthing;

          devices = {
            "allyx" = {id = "XTEVJX2-DBEFN4X-UCG43YR-V4FOQYU-DMM2WH4-AMCC5FS-42UB3DM-KUDVHQL";};
            "eterna" = {id = "ZAD2MVO-I2OQII4-C3T756B-BEBQMM6-Q4ILH2H-5CR3TMI-DR4VBFD-GLRVOQK";};
            "fallarbor" = {id = "P4URLH4-YWLMO6J-W62ET7H-TQAO3Y6-T2FAYOY-C2VTI65-VQXHVGG-NQ76PAZ";};
            "fortree" = {id = "S6PVA3I-EKOCGIU-GFX7AE6-FXM45OW-JTYN5LJ-UZ4LADZ-NNAJGDD-KST2VAG";};
            "groudon" = {id = "VOEAEAG-NP5Z3BM-DK5FO75-6G4NKSJ-3EUNFSV-VIR4KDH-OM6ZN7L-OOQKCQJ";};
            "jubilife" = {id = "52MTCMC-PKEWSAU-HADMTZU-DY5EKFO-B323P7V-OBXLNTQ-EJY7F7Y-EUWFBQX";};
            "kyogre" = {id = "SBQNUXS-H4XDJ3E-RBHJPT5-45WDJJA-2U43M4P-23XGUJ7-E3CNNKZ-BXSGIA3";};
            "oreburgh" = {id = "RFVF6DA-CQJLXTP-RKMYEB3-D2KMWJH-3Z2CIAN-PNYOXI6-FIDBFWG-JJA57AX";};
            "pacifidlog" = {id = "6EBVXYI-HZW4LQI-T6L3TTI-DZEBXJM-RP3DW7N-BCAG6FC-G2654DN-XJFSLQD";};
            "petalburg" = {id = "O75EK2H-YBXPM5D-PBYV7XB-DJKFL3E-OFZBB7H-MLCD2UT-NXQRMDG-BTZZQQH";};
            "rp5" = {id = "5AKCXRS-XU7BBSS-RDPSSLG-4BDOZ4K-OXLFQZX-HJSM53W-4GLSOAC-RZ7APA7";};
            "rpclassic" = {id = "EDNFUWI-UFYEOPI-QPJIEWF-NXVEGZ6-2J7IXW7-X22L27F-VU6JKSB-CH6GDAO";};
            "rustboro" = {id = "NY53BFH-CPVCXGH-MI5AT7E-WBK7TXS-5NQDSCW-J5BALLV-EGS2VJL-CMED2AH";};
            "slateport" = {id = "MDJFDUG-UJAXQXI-AMEF2AR-PBMD5QK-Z5ZG6AA-RCJCU3M-GZHQQEA-X2JGOAK";};
            "snowpoint" = {id = "TFSZWZB-EDIFV2P-333APP2-T655TM4-2XGA7QA-P22Z36W-3RNGX2C-DLETAQ7";};
            "sootopolis" = {id = "7QGSZ2D-CGMLPWD-OCFCBXP-7746W7F-COFV52F-Q2PMCAS-GV5DCSV-6NIXDQJ";};
            "thor" = {id = "B33X5WA-S6P4XEE-VURE4PB-WKMXHLP-6AG55LZ-QIG6ZJG-GDGXWAD-EDVIRAF";};
            "verdanturf" = {id = "CQ7A2KW-2JRZHEO-NF6NZLY-C2OX4SO-EPKQRMV-7YBSSFA-FJ2CW2P-NOIKPQB";};
          };

          folders = lib.mkMerge [
            {
              "sync" = {
                devices = ["allyx" "eterna" "fallarbor" "fortree" "groudon" "jubilife" "kyogre" "oreburgh" "pacifidlog" "petalburg" "rustboro" "slateport" "snowpoint" "sootopolis" "verdanturf"];
                id = "default";
                path = "~/sync";
                versioning = {
                  params.cleanoutDays = "5";
                  type = "trashcan";
                };
              };

              "screenshots" = {
                devices = ["fallarbor" "oreburgh" "jubilife" "pacifidlog" "petalburg" "rustboro" "slateport" "snowpoint" "sootopolis" "verdanturf"];
                id = "screenshots";
                path = "~/pics/screenshots";
                versioning = {
                  params.cleanoutDays = "5";
                  type = "trashcan";
                };
              };

              "roms" = {
                devices = ["jubilife" "oreburgh" "pacifidlog" "petalburg" "rp5" "rpclassic" "rustboro" "sootopolis" "thor"];
                id = "emudeck";
                versioning = {
                  params.cleanoutDays = "3";
                  type = "trashcan";
                };
              };
            }
            {
              "roms" = {
                enable = cfg.syncROMs;
                path = cfg.romsPath;
              };
            }
          ];
        in {
          enable = true;
          cert = cfg.certFile;
          configDir = "${config.services.syncthing.dataDir}/.syncthing";
          dataDir = "/home/${cfg.user}";
          key = cfg.keyFile;
          openDefaultPorts = true;
          inherit (cfg) user;

          settings = {
            options = {
              localAnnounceEnabled = true;
              relaysEnabled = true;
              urAccepted = -1;
            };

            inherit devices folders;
          };
        };
      };
    };
  };
}
