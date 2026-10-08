# CLIProxyAPI as a user service, API endpoints require no client auth.
# One-time login (as mantas on ag):
#   cli-proxy-api --config <config path from ExecStart> --<provider>-login
#   systemctl --user restart cli-proxy-api
{self, ...}: {
  flake.modules.nixos."services-cli-proxy-api" = {pkgs, ...}: let
    port = 8317;
    pkg = self.packages.${pkgs.stdenv.hostPlatform.system}.cli-proxy-api;
    configFile = pkgs.writeText "cli-proxy-api-config.yaml" ''
      config-version: 8
      server:
        host: "0.0.0.0"
        port: ${toString port}
      management:
        secret-key: ""
        disable-control-panel: true
      access:
        api-keys: []
      oauth:
        auth-dir: "~/.cli-proxy-api"
    '';
  in {
    environment.systemPackages = [pkg];

    networking.firewall.allowedTCPPorts = [port];

    systemd.user.services.cli-proxy-api = {
      description = "CLIProxyAPI";
      wantedBy = ["default.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.ConditionUser = "!root";
      serviceConfig = {
        ExecStart = "${pkg}/bin/cli-proxy-api --config ${configFile}";
        WorkingDirectory = "%h";
        Restart = "always";
        RestartSec = 2;
        NoNewPrivileges = true;
      };
    };
  };
}
