{inputs, ...}: {
  flake.modules.nixos."services-hermes" = {pkgs-unstable, ...}: {
    imports = [
      inputs.hermes-agent.nixosModules.default
    ];

    services.hermes-agent = {
      enable = true;
      environmentFiles = ["/var/lib/hermes/env"];

      authFile = "/var/lib/hermes/auth.json";
      # authFileForceOverwrite = true; # overwrite on every activation

      addToSystemPackages = true;

      extraDependencyGroups = ["messaging" "voice"];

      # Timed session resets are opt-in since Hermes removed the core policy.
      extraPlugins = [
        (pkgs-unstable.fetchFromGitHub {
          name = "hermes-session-reset-policy";
          owner = "fastfinge";
          repo = "hermes-session-reset-policy";
          # Skip slash commands so /new after an idle boundary resets only once.
          rev = "48391fb352f8546ea1fb4fa80490653c285f5063";
          hash = "sha256-sEoSnALK1CdJ4N9sFC/tMvMuP4z/0lLE7x9YFOWEynw=";
        })
      ];

      settings = {
        plugins.enabled = ["hermes-session-reset-policy"];

        model.default = "openai/gpt-6.1-sol";

        agent = {
          reasoning_effort = "medium";
        };

        approvals = {
          mode = "off";
          cron_mode = "approve";
        };

        session_reset = {
          mode = "idle";
          # Reset on the first user message after 12 hours of inactivity.
          idle_minutes = 60 * 12;
        };

        stt.enabled = false;
      };

      extraPackages = with pkgs-unstable; [
        # python313
        # python313Packages.pip

        coreutils
        gawk
        git
        curl
        wget
        jq
        file
        which
        tree
        unzip
        zip
        ripgrep
        fd
        uv

        python3
        sqlite
        cloudflared

        imagemagick
        exiftool
        ffmpeg

        python313Packages.edge-tts
        openai-whisper
        sox
        espeak-ng
        yt-dlp
        caddy
        gh

        chromium
        nodejs_24
      ];
    };
  };
}
