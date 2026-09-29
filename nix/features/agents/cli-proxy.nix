# CLIProxyAPI (https://github.com/router-for-me/CLIProxyAPI) as a local daemon.
#
# One-time headless OAuth login (e.g. Codex) after first deploy:
#   1. From your laptop:  ssh -L 1455:localhost:1455 ag
#   2. On ag:             sudo -u cli-proxy-api HOME=/var/lib/cli-proxy-api \
#                           cli-proxy-api --config /run/cli-proxy-api/config.yaml \
#                           --codex-login --no-browser
#   3. Open the printed URL locally (the -L tunnel forwards the callback), finish auth.
#   4. Back on ag:        systemctl restart cli-proxy-api
#
# The service must be running (so /run/cli-proxy-api/config.yaml exists) before step 2;
# tokens are written under auth-dir (/var/lib/cli-proxy-api) where the daemon reads them.
{...}: {
  flake.modules.nixos."agents-cli-proxy" = {
    self,
    pkgs,
    config,
    lib,
    ...
  }: let
    pkg = self.packages.${pkgs.stdenv.hostPlatform.system}.cli-proxy-api;

    port = 8317;
    stateDir = "/var/lib/cli-proxy-api";
    runtimeConfig = "/run/cli-proxy-api/config.yaml";

    # Renders the runtime config.yaml, injecting the downstream API key and the
    # management secret-key from agenix-provided systemd credentials. The whole
    # YAML lives here (rather than a writeText template merged at runtime) so the
    # top-level `remote-management` block appears exactly once and stays valid.
    # Provider sections (claude-api-key / gemini-api-key / codex-api-key, etc.)
    # can be appended to this heredoc later once accounts are configured.
    renderConfig = pkgs.writeShellApplication {
      name = "cli-proxy-api-render-config";
      runtimeInputs = [pkgs.coreutils];
      text = ''
        api_key=$(<"$CREDENTIALS_DIRECTORY/api-keys")
        mgmt_key=$(<"$CREDENTIALS_DIRECTORY/mgmt-key")

        umask 077
        cat >"$RUNTIME_DIRECTORY/config.yaml" <<EOF
        host: "127.0.0.1"
        port: ${toString port}
        auth-dir: "${stateDir}"

        remote-management:
          allow-remote: false
          secret-key: "$mgmt_key"

        api-keys:
          - "$api_key"
        EOF
        chmod 0600 "$RUNTIME_DIRECTORY/config.yaml"
      '';
    };
  in {
    age.secrets.cli-proxy-api-keys.file = ../../_lib/secrets/cli-proxy-api-keys.age;
    age.secrets.cli-proxy-mgmt-key.file = ../../_lib/secrets/cli-proxy-mgmt-key.age;

    users.users.cli-proxy-api = {
      isSystemUser = true;
      group = "cli-proxy-api";
      home = stateDir;
    };
    users.groups.cli-proxy-api = {};

    # Available for the one-time manual OAuth login described at the top of this file.
    environment.systemPackages = [pkg];

    systemd.services.cli-proxy-api = {
      description = "CLIProxyAPI local proxy daemon";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";

        User = "cli-proxy-api";
        Group = "cli-proxy-api";

        StateDirectory = "cli-proxy-api";
        RuntimeDirectory = "cli-proxy-api";
        RuntimeDirectoryMode = "0700";
        WorkingDirectory = stateDir;

        LoadCredential = [
          "api-keys:${config.age.secrets.cli-proxy-api-keys.path}"
          "mgmt-key:${config.age.secrets.cli-proxy-mgmt-key.path}"
        ];

        ExecStartPre = "${renderConfig}/bin/cli-proxy-api-render-config";
        ExecStart = "${pkg}/bin/cli-proxy-api --config ${runtimeConfig}";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };
  };
}
