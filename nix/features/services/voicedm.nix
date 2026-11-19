# Hands-free voice conversation with a local LLM in the browser
# Expects Ollama and Chatterbox on the same host (`services-ollama`,
# `containers-chatterbox`)
{inputs, ...}: {
  flake.modules.nixos."services-voicedm" = {
    lib,
    pkgs,
    config,
    ...
  }: let
    port = 8780;

    tailscaleServe = pkgs.writeShellApplication {
      name = "voicedm-tailscale-serve";
      runtimeInputs = [pkgs.coreutils config.services.tailscale.package];
      text =
        /*
        bash
        */
        ''
          # Waits for the one-time `tailscale up` instead of failing the boot
          until tailscale status --peers=false >/dev/null 2>&1; do
            sleep 10
          done
          exec tailscale serve --bg ${toString port}
        '';
    };
  in {
    imports = [
      inputs.voicedm.nixosModules.default
    ];

    services.voicedm = {
      enable = true;
      # Not exposed directly: browsers need HTTPS for the microphone
      host = "127.0.0.1";
      inherit port;
    };

    # With the `services-tailscale` feature the page is published on the
    # tailnet over HTTPS; the call audio (UDP) goes over the same interface
    systemd.services.voicedm-tailscale-serve = lib.mkIf config.services.tailscale.enable {
      description = "Publish voicedm on the tailnet";
      after = ["tailscaled.service"];
      wants = ["tailscaled.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "1min";
        ExecStart = lib.getExe tailscaleServe;
      };
    };
  };
}
