{...}: {
  flake.modules.nixos."services-ollama" = {pkgs-unstable, ...}: {
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      openFirewall = true;
      package = pkgs-unstable.ollama-cpu;
      loadModels = ["gemma4:e4b-it-qat"];
    };
  };
}
