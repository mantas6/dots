{...}: {
  flake.modules.nixos."services-agent-dots-pr" = {
    config,
    lib,
    pkgs,
    pkgs-unstable,
    ...
  }: let
    opencodeAuthSecret = ../../../_lib/secrets/opencode-auth.age;
    ghTokenSecret = ../../../_lib/secrets/gh-token.age;

    opencodeConfig = pkgs.writeText "opencode.json" (builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      autoupdate = false;
      enabled_providers = ["openai"];
      plugin = [];
      share = "disabled";
      permission = {
        bash = "allow";
        edit = "allow";
        read = "allow";
      };
    });

    gitConfig = pkgs.writeText "gitconfig" ''
      [user]
      	name = "Mantas (agent)"
      	email = 6524518+mantas6@users.noreply.github.com
      [credential "https://github.com"]
      	helper = !gh auth git-credential
      [push]
      	autoSetupRemote = true
      [init]
      	defaultBranch = main
    '';

    agentDotsPr = pkgs.writeShellApplication {
      name = "agent-dots-pr";
      runtimeInputs = [
        pkgs-unstable.opencode
        pkgs.git
        pkgs.gh
        pkgs.nix
        pkgs.alejandra
        pkgs.shfmt
        pkgs.shellcheck
        pkgs.jq
        pkgs.ripgrep
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnugrep
        pkgs.gnused
      ];
      text =
        /*
        bash
        */
        ''
          # Load the GitHub token (command substitution strips trailing newlines).
          GH_TOKEN=$(<"$CREDENTIALS_DIRECTORY/gh-token")
          export GH_TOKEN

          # Seed opencode auth. Codex OAuth rotates the refresh token and rewrites
          # auth.json, so only overwrite when the seeded credential changed or the
          # local copy is missing; otherwise keep the rotated tokens in place.
          auth_src="$CREDENTIALS_DIRECTORY/opencode-auth"
          auth_dst="$XDG_DATA_HOME/opencode/auth.json"
          seed_file="$STATE_DIRECTORY/.auth-seed"
          new_hash=$(sha256sum "$auth_src" | cut -d' ' -f1)
          old_hash=""
          [[ -f "$seed_file" ]] && old_hash=$(<"$seed_file")
          if [[ "$new_hash" != "$old_hash" || ! -f "$auth_dst" ]]; then
            install -Dm600 "$auth_src" "$auth_dst"
            printf '%s\n' "$new_hash" >"$seed_file"
          fi

          # Skip (spending no tokens) if an agent PR is already open.
          open_count=$(gh pr list -R mantas6/dots --state open --json headRefName \
            --jq '[.[]|select(.headRefName|startswith("agent/"))]|length')
          if [[ "$open_count" -gt 0 ]]; then
            echo "open agent/* PR exists, skipping"
            exit 0
          fi

          work=$(mktemp -d)
          git clone https://github.com/mantas6/dots "$work/dots"
          cd "$work/dots"

          opencode run \
            --agent build \
            --model openai/gpt-5.6-sol \
            --variant medium \
            --auto \
            --title "agent-dots-pr" \
            "$(<${./prompt.md})"
        '';
    };
  in {
    age.secrets.opencode-auth.file = opencodeAuthSecret;
    age.secrets.gh-token.file = ghTokenSecret;

    systemd.services.agent-dots-pr = {
      description = "Open a low-risk PR on mantas6/dots via opencode";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      restartIfChanged = false;

      environment = {
        HOME = "/var/lib/agent-dots-pr";
        XDG_DATA_HOME = "/var/lib/agent-dots-pr/.local/share";
        XDG_CONFIG_HOME = "/var/lib/agent-dots-pr/.config";
        XDG_CACHE_HOME = "/var/cache/agent-dots-pr";
        OPENCODE_CONFIG = "${opencodeConfig}";
        GIT_CONFIG_GLOBAL = "${gitConfig}";
        GH_CONFIG_DIR = "/var/lib/agent-dots-pr/gh";
        GH_NO_UPDATE_NOTIFIER = "1";
        GH_PROMPT_DISABLED = "1";
        GIT_TERMINAL_PROMPT = "0";
        OPENCODE_DISABLE_AUTOUPDATE = "1";
        OPENCODE_DISABLE_LSP_DOWNLOAD = "1";
        OPENCODE_DISABLE_CLAUDE_CODE = "1";
        NO_COLOR = "1";
      };

      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe agentDotsPr;
        DynamicUser = true;
        StateDirectory = "agent-dots-pr";
        CacheDirectory = "agent-dots-pr";
        LoadCredential = [
          "opencode-auth:${config.age.secrets.opencode-auth.path}"
          "gh-token:${config.age.secrets.gh-token.path}"
        ];
        WorkingDirectory = "/tmp";
        TimeoutStartSec = "3h";
        Nice = 10;

        # Hardening.
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        DevicePolicy = "closed";
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        RemoveIPC = true;
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        SystemCallArchitectures = "native";
        SystemCallFilter = ["@system-service" "~@privileged"];
        UMask = "0077";
        MemoryDenyWriteExecute = false;
      };
    };

    systemd.timers.agent-dots-pr = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*-*-* 05:00:00";
        Persistent = false;
      };
    };
  };
}
