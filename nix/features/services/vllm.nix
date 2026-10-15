{...}: {
  flake.modules.nixos."services-vllm" = {
    pkgs-unstable,
    lib,
    ...
  }: let
    port = 8000;
  in {
    systemd.services.vllm = {
      description = "vLLM OpenAI-compatible inference server";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      environment = {
        HF_HOME = "/var/lib/vllm";
        VLLM_CPU_KVCACHE_SPACE = "4";
      };
      serviceConfig = {
        ExecStart = lib.escapeShellArgs [
          (lib.getExe pkgs-unstable.vllm)
          "serve"
          "Qwen/Qwen3-1.7B"
          "--host"
          "0.0.0.0"
          "--port"
          (toString port)
        ];
        DynamicUser = true;
        StateDirectory = "vllm";
        WorkingDirectory = "/var/lib/vllm";
        Restart = "on-failure";
        RestartSec = 10;
        # Model download and warmup can take a while
        TimeoutStartSec = "15min";
      };
    };

    networking.firewall.allowedTCPPorts = [port];
  };
}
