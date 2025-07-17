{ config, pkgs, ... }:
{
  systemd.services.ledger = {
    description = "Ledger API ervice";
    after = [ "network.target" "wg-quick-wg0.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.ledger}/bin/main";
      WorkingDirectory = "/var/lib/ledger";
      Restart = "always";
      Environment = [ "DATABASE_PATH=/var/lib/ledger/data.db" ];
    };
    preStart = ''
      if [ ! -f /var/lib/ledger/data.db ]; then
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/ledger/data.db < /var/lib/ledger/schema.sql
      fi
    '';
  };

  system.activationScripts = {
    setupLedgerDir = ''
      mkdir -p /var/lib/ledger
      cp ${./schema.sql} /var/lib/ledger/schema.sql
      chown nobody:nogroup /var/lib/ledger
      chmod 755 /var/lib/ledger
    '';
  };

  # Restrict service to VPN interface
  # networking.firewall.allowedTCPPorts = [];
  # networking.firewall.interfaces.wg0.allowedTCPPorts = [ 8080 ];
}
