{...}: {
  flake.modules.nixos.base = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.features.send-machine-stats;
    systems = import ../../../_lib/systems.nix;
    statsConfig = pkgs.writeText "fastfetch-stats.jsonc" (builtins.toJSON cfg.settings);

    sendMachineStats = pkgs.writeShellApplication {
      name = "send-machine-stats";
      runtimeInputs = [pkgs.fastfetch pkgs.curl pkgs.systemd pkgs.gnugrep];
      text =
        /*
        bash
        */
        ''
          BASE_URL=$(<"$CREDENTIALS_DIRECTORY/sat-base-url")
          stats=$(fastfetch --config ${statsConfig} --json)
          endpoint="''${BASE_URL%/}/api/machine/$MACHINE_NAME"

          printf '{"stats":%s}\n' "$stats" | curl \
            --fail \
            --silent \
            --show-error \
            --connect-timeout 10 \
            --max-time 30 \
            --header 'Content-Type: application/json' \
            --data-binary @- \
            "$endpoint"
        '';
    };
  in
    lib.mkIf (builtins.hasAttr config.networking.hostName systems) {
      age.secrets.sat-base-url.file = ../../../_lib/secrets/sat-base-url.age;

      systemd.services.send-machine-stats = {
        description = "Send machine statistics";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        environment = {
          MACHINE_NAME = config.networking.hostName;
        };
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          SupplementaryGroups = ["systemd-journal"];
          LoadCredential = "sat-base-url:${config.age.secrets.sat-base-url.path}";
          ExecStart = "${sendMachineStats}/bin/send-machine-stats";
        };
      };

      systemd.timers.send-machine-stats = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "10s";
          OnUnitActiveSec = "1min";
          RandomizedDelaySec = "10s";
        };
      };
    };
}
