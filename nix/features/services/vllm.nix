{...}: {
  flake.modules.nixos."services-vllm" = {
    pkgs-unstable,
    lib,
    ...
  }: let
    vllm = lib.getExe pkgs-unstable.vllm;
    # API model name -> Hugging Face repo, downloaded on first request
    models = {
      "qwen3-1.7b" = "Qwen/Qwen3-1.7B";
      "qwen3-4b" = "Qwen/Qwen3-4B";
    };
  in {
    # vLLM serves a single model per process, llama-swap starts the requested one on demand
    services.llama-swap = {
      enable = true;
      listenAddress = "0.0.0.0";
      port = 8000;
      openFirewall = true;
      settings = {
        # Model download and warmup can take a while on CPU
        healthCheckTimeout = 900;
        models =
          lib.mapAttrs (name: repo: {
            cmd = "${vllm} serve ${repo} --served-model-name ${name} --host 127.0.0.1 --port \${PORT}";
            ttl = 600;
          })
          models;
      };
    };

    systemd.services.llama-swap = {
      environment = {
        HOME = "/var/lib/llama-swap";
        VLLM_CPU_KVCACHE_SPACE = "4";
      };
      serviceConfig = {
        StateDirectory = "llama-swap";
        # PyTorch JIT needs writable executable memory
        MemoryDenyWriteExecute = lib.mkForce false;
      };
    };
  };
}
