{...}: {
  flake.modules.nixos."services-machine-stats" = {
    config,
    pkgs,
    ...
  }: let
    sendMachineStats = pkgs.writeShellApplication {
      name = "send-machine-stats";
      runtimeInputs = [pkgs.fastfetch pkgs.curl];
      text =
        /*
        bash
        */
        ''
          set -euo pipefail

          config="''${FASTFETCH_CONFIG:-all.jsonc}"
          BASE_URL=$(<"$CREDENTIALS_DIRECTORY/sat-base-url")
          stats=$(fastfetch --config "$config" --json)
          endpoint="''${BASE_URL%/}/api/machine/$MACHINE_NAME"

          exec 3<<<"url = \"$endpoint\""
          printf '{"stats":%s}\n' "$stats" | curl \
            --config /dev/fd/3 \
            --fail \
            --silent \
            --header 'Content-Type: application/json' \
            --data-binary @-
        '';
    };
  in {
    age.secrets.sat-base-url.file = ../../../lib/secrets/sat-base-url.age;

    systemd.services.send-machine-stats = {
      description = "Send machine statistics";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      environment = {
        FASTFETCH_CONFIG = "all.jsonc";
        MACHINE_NAME = config.networking.hostName;
      };
      serviceConfig = {
        Type = "oneshot";
        DynamicUser = true;
        LoadCredential = "sat-base-url:${config.age.secrets.sat-base-url.path}";
        ExecStart = "${sendMachineStats}/bin/send-machine-stats";
      };
    };

    systemd.timers.send-machine-stats = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "1min";
      };
    };
  };
}
