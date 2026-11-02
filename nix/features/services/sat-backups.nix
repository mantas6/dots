{...}: {
  flake.modules.nixos."services-sat-backups" = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.features.satBackups;

    # Pulls the latest backup from Sat and marks it as retrieved.
    # Talks to `<base url>/api/backups/{query,retrieve,mark}` with a bearer
    # token that has the `backups` ability.
    satBackup = pkgs.writeShellApplication {
      name = "sat-backup";
      runtimeInputs = with pkgs; [curl jq openssl coreutils findutils];
      text =
        /*
        bash
        */
        ''
          base_url=$(<"$CREDENTIALS_DIRECTORY/sat-base-url")
          token=$(<"$CREDENTIALS_DIRECTORY/backups-token")
          api="''${base_url%/}/api/backups"

          # request <method> <endpoint> <json params> [curl args...]
          # Every request carries the host name plus the given params.
          request() {
            local method=$1 endpoint=$2 params=$3
            shift 3

            jq -n --arg host "$HOST" --argjson params "$params" '{host: $host} + $params' \
              | curl \
                --fail-with-body \
                --silent \
                --show-error \
                --request "$method" \
                --header 'Content-Type: application/json' \
                --header 'Accept: application/json' \
                --header "Authorization: Bearer $token" \
                --data-binary @- \
                "$@" \
                "$api/$endpoint"
          }

          mkdir -p "$OUTPUT_PATH"

          filename=$(request GET query '{}')

          if [[ "$filename" == "Up-to-date" ]]; then
            echo "Already up to date"
            exit 0
          fi

          if [[ -z "$filename" || "$filename" == */* ]]; then
            echo "Unexpected filename received: $filename" >&2
            exit 1
          fi

          echo "Filename received: $filename"
          target="$OUTPUT_PATH/$filename"

          request GET retrieve "$(jq -n --arg filename "$filename" '{filename: $filename}')" \
            --output "$target.part"
          mv "$target.part" "$target"
          echo "Wrote $target"

          checksum=$(openssl sha512 -r "$target" | cut -d ' ' -f 1)
          available_space=$(df -k --output=avail "$OUTPUT_PATH" | tail -n 1 | tr -d ' ')

          result=$(request POST mark "$(jq -n \
            --arg filename "$filename" \
            --arg checksum "$checksum" \
            --arg available_space "$available_space" \
            '$ARGS.named')")
          echo "Result: $result"

          if [[ "$result" != "OK" ]]; then
            echo "Server did not accept the backup" >&2
            exit 1
          fi

          echo "Removing backups older than $KEEP_FOR days"
          find "$OUTPUT_PATH" -type f -mtime "+$KEEP_FOR" -exec rm -v {} +

          if [[ -n "$MONTHLY_PATH" && "$(date +%-d)" -eq 1 ]]; then
            echo "Keeping a monthly copy"
            mkdir -p "$MONTHLY_PATH"
            cp -nv "$target" "$MONTHLY_PATH/$filename"
          fi
        '';
    };
  in {
    options.features.satBackups = {
      outputPath = lib.mkOption {
        type = lib.types.str;
        default = "/home/mantas/Offload/Sat/backups";
        description = "Directory that receives the daily backups";
      };

      monthlyPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/home/mantas/Offload/Sat/monthly";
        description = "Directory that keeps a copy of the first backup of each month (null to disable)";
      };

      keepFor = lib.mkOption {
        type = lib.types.int;
        default = 365;
        description = "Days to keep backups in outputPath";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName;
        description = "Host name the backups are registered under";
      };
    };

    config = {
      age.secrets = {
        sat-base-url.file = ../../_lib/secrets/sat-base-url.age;
        backups-token.file = ../../_lib/secrets/backups-token.age;
      };

      systemd.services.sat-backups = {
        description = "Pull the latest backup from Sat";

        after = ["network-online.target"];
        wants = ["network-online.target"];

        environment = {
          HOST = cfg.host;
          OUTPUT_PATH = cfg.outputPath;
          MONTHLY_PATH = toString cfg.monthlyPath;
          KEEP_FOR = toString cfg.keepFor;
        };

        serviceConfig = {
          Type = "oneshot";
          User = "mantas";
          LoadCredential = [
            "sat-base-url:${config.age.secrets.sat-base-url.path}"
            "backups-token:${config.age.secrets.backups-token.path}"
          ];
          ExecStart = "${satBackup}/bin/sat-backup";
        };

        startAt = ["03:00" "09:00"];
      };

      systemd.timers.sat-backups = {
        timerConfig = {
          Persistent = true;
        };
      };
    };
  };
}
