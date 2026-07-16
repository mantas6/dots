{inputs, ...}: {
  flake.nixosModules."services-hermes" = {pkgs-unstable, ...}: {
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

      settings = {
        model.default = "openai/gpt-5.6-terra";

        agent = {
          reasoning_effort = "medium";
        };

        approvals = {
          mode = "off";
          cron_mode = "approve";
        };

        stt.enabled = false;
      };

      extraPackages = with pkgs-unstable; [
        # python313
        # python313Packages.pip

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

        imagemagick
        exiftool
        ffmpeg
        imagemagick

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
