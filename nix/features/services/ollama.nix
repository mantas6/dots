{...}: {
  flake.modules.nixos."services-ollama" = {pkgs-unstable, ...}: {
    services.ollama = {
      enable = true;
      package = pkgs-unstable.ollama-cpu;
      loadModels = ["gemma4:e4b-it-qat"];
    };
  };
}
