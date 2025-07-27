{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.ledger;
in
{

  options.services.ledger = {
    enable = mkEnableOption "Ledger API service";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port on which the ledger service will listen";
    };

    user = mkOption {
      type = types.str;
      default = "ledger";
      description = "User account under which ledger runs";
    };

    group = mkOption {
      type = types.str;
      default = "ledger";
      description = "Group under which ledger runs";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/ledger";
      description = "Directory where ledger stores its data";
    };

    databasePath = mkOption {
      type = types.str;
      default = "/var/lib/ledger/data.db";
      description = "Path to the SQLite database file";
    };

    executableName = mkOption {
      type = types.str;
      default = "server";  # Changed from "main" to match your flake
      description = "Name of the executable to run";
    };

    waitForVPN = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to wait for VPN connection before starting";
    };

    vpnInterface = mkOption {
      type = types.str;
      default = "wg0";
      description = "VPN interface to restrict service to";
    };

    restrictToVPN = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to restrict firewall access to VPN interface only";
    };
  };

  config = mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.ledger = {
      description = "Ledger API Service";
      after = [ "network.target" ] ++ optional cfg.waitForVPN "wg-quick-${cfg.vpnInterface}.service";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${pkgs.ledger}/bin/${cfg.executableName}";
        WorkingDirectory = cfg.dataDir;
        Restart = "always";
        RestartSec = "10s";
        
        NoNewPrivileges = true;
        PrivateTmp = true;
        # ProtectSystem = "strict";
        # ProtectHome = true;
        # ReadWritePaths = [ cfg.dataDir ];
      };

      environment = {
        PORT = toString cfg.port;
        DATABASE_PATH = cfg.databasePath;
        DB_PATH = cfg.databasePath; # Keep both for compatibility
      };
    };

    # Firewall configuration
    networking.firewall = mkMerge [
      (mkIf (!cfg.restrictToVPN) {
        allowedTCPPorts = [ cfg.port ];
      })
      (mkIf cfg.restrictToVPN {
        interfaces.${cfg.vpnInterface}.allowedTCPPorts = [ cfg.port ];
      })
    ];
  };
}
