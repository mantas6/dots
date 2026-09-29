# Requires the `hardware-nvidia` feature
{...}: {
  flake.modules.nixos."services-ollama" = {
    pkgs-unstable,
    lib,
    inputs,
    ...
  }: let
    pkgs-unstable-unfree = import inputs.nixpkgs-unstable {
      system = pkgs-unstable.stdenv.hostPlatform.system;
      config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "cuda_cccl"
          "cuda_cudart"
          "cuda_nvcc"
          "cuda_nvrtc"
          "libcublas"
        ];
    };
  in {
    services.ollama = {
      enable = true;
      package = pkgs-unstable-unfree.ollama-cuda;
      # QAT build (6.1GB) fits in 8GB VRAM with headroom for context
      loadModels = ["gemma4:e4b-it-qat"];
    };
  };
}
