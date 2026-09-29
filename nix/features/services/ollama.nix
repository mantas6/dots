# Requires the `hardware-nvidia` feature
{...}: {
  flake.modules.nixos."services-ollama" = {pkgs, ...}: {
    # allowUnfreePackages merges across modules, unlike allowUnfreePredicate
    nixpkgs.config.allowUnfreePackages = [
      "cuda_cccl"
      "cuda_compat"
      "cuda_cudart"
      "cuda_nvcc"
      "libcublas"
    ];

    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
    };
  };
}
