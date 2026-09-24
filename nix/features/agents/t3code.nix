{...}: {
  flake.modules.nixos."agents-t3code" = {
    lib,
    config,
    pkgs,
    pkgs-unstable,
    ...
  }: let
    # Keys from ServerSettings in t3code 0.0.40 (packages/contracts/src/settings.ts)
    settings = {
      enableLegacyTokenStreaming = false;
    };
    keybindings = [];

    settingsFile = pkgs.writeText "t3-settings.json" (builtins.toJSON settings);
    keybindingsFile = pkgs.writeText "t3-keybindings.json" (builtins.toJSON keybindings);

    seedScript = pkgs.writeShellApplication {
      name = "t3code-seed-settings";
      runtimeInputs = [pkgs.jq];
      text =
        /*
        bash
        */
        ''
          dir="''${T3CODE_HOME:-$HOME/.t3}/userdata"
          mkdir -p "$dir"

          # Print the file if it holds JSON of the given type, else back it up and print the fallback
          read_json() {
              if jq -e --arg type "$2" 'type == $type' "$1" >/dev/null 2>&1; then
                  cat "$1"
              else
                  [[ -e $1 ]] && mv "$1" "$1.bak"
                  echo "$3"
              fi
          }

          write_json() {
              local tmp
              tmp=$(mktemp "$1.XXXXXX")
              printf '%s\n' "$2" >"$tmp"
              mv "$tmp" "$1"
          }

          current=$(read_json "$dir/settings.json" object '{}')
          merged=$(jq -s '.[0] * .[1]' - ${settingsFile} <<<"$current")
          write_json "$dir/settings.json" "$merged"
        ''
        + lib.optionalString (keybindings != []) ''

          current=$(read_json "$dir/keybindings.json" array '[]')
          merged=$(jq -s '.[1] as $new | [.[0][] | select(. as $r | $new | any(.command == $r.command and .when == $r.when) | not)] + $new' - ${keybindingsFile} <<<"$current")
          write_json "$dir/keybindings.json" "$merged"
        '';
    };
  in {
    systemd.user.services.t3code = {
      description = "T3 Code server";
      wantedBy = ["default.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.ConditionUser = "!root";
      environment.SHELL = lib.getExe config.users.users.mantas.shell;
      serviceConfig = {
        ExecStartPre = "-${lib.getExe seedScript}";
        ExecStart = "${pkgs-unstable.t3code}/bin/t3 serve --mode web --host 0.0.0.0 --no-browser";
        WorkingDirectory = "%h";
        Restart = "always";
        RestartSec = 2;
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };
  };
}
