# Chatterbox Turbo TTS served over the network, started on demand
# Requires the `hardware-nvidia-headless` feature
{...}: {
  flake.modules.nixos."containers-chatterbox" = {
    pkgs,
    config,
    ...
  }: let
    port = 8004;
    backendPort = 18004;
    dataDir = "/var/lib/chatterbox";
    idleTime = "15min";
  in {
    # Exposes the GPU to containers via CDI (`--device nvidia.com/gpu=all`)
    hardware.nvidia-container-toolkit.enable = true;

    virtualisation.oci-containers.containers.chatterbox = {
      # Pinned build of `main-nvidia` (CUDA 12.8 runtime, defaults to Turbo)
      image = "ghcr.io/devnen/chatterbox-tts-server:sha-f9fb21c-nvidia";

      # Started by the socket proxy, not at boot
      autoStart = false;

      ports = ["127.0.0.1:${toString backendPort}:8004"];
      devices = ["nvidia.com/gpu=all"];

      environment = {
        HF_HUB_ENABLE_HF_TRANSFER = "1";
        NVIDIA_VISIBLE_DEVICES = "all";
        NVIDIA_DRIVER_CAPABILITIES = "compute,utility";
      };

      volumes = [
        "${dataDir}/hf_cache:/app/hf_cache"
        "${dataDir}/model_cache:/app/model_cache"
        # Custom reference clips (>5s wav); bundled voices stay in /app/voices
        "${dataDir}/reference_audio:/app/reference_audio"
      ];
    };

    systemd.services.docker-chatterbox = {
      unitConfig = {
        # Stop (and free VRAM) once the proxy no longer needs it
        StopWhenUnneeded = true;

        # A model that cannot load (bad download, VRAM taken) fails the
        # readiness probe; stop retrying after a few attempts instead of
        # churning the GPU on every incoming connection
        StartLimitIntervalSec = "10min";
        StartLimitBurst = 3;
      };

      # Root-owned state under /var/lib/chatterbox (the image runs as root)
      serviceConfig.StateDirectory = [
        "chatterbox/hf_cache"
        "chatterbox/model_cache"
        "chatterbox/reference_audio"
      ];

      # Hold the proxy until the API answers and reports the model as loaded.
      # Upstream loads the model before serving HTTP and never retries, so a
      # response with `loaded: false` is final and must fail the unit so
      # systemd restarts the container. The first start also downloads ~4GB
      # of weights, hence the long bound (TimeoutStartSec is 0).
      serviceConfig.ExecStartPost = pkgs.writeShellScript "wait-chatterbox" ''
        for _ in $(seq 900); do
          if info=$(${pkgs.curl}/bin/curl -sf http://127.0.0.1:${toString backendPort}/api/model-info); then
            echo "$info" | ${pkgs.jq}/bin/jq -e '.loaded == true' >/dev/null && exit 0
            echo "chatterbox: server is up but the model failed to load" >&2
            exit 1
          fi
          sleep 2
        done
        echo "chatterbox: timed out waiting for the API" >&2
        exit 1
      '';
    };

    # Listens on the public port; first connection starts the container
    systemd.sockets.chatterbox-proxy = {
      wantedBy = ["sockets.target"];
      listenStreams = ["0.0.0.0:${toString port}"];
    };

    systemd.services.chatterbox-proxy = {
      requires = ["docker-chatterbox.service"];
      after = ["docker-chatterbox.service"];
      serviceConfig.ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd --exit-idle-time=${idleTime} 127.0.0.1:${toString backendPort}";
    };

    networking.firewall.allowedTCPPorts = [port];
  };
}
