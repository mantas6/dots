{...}: {
  flake.modules.nixos."services-ollama" = {pkgs-unstable, ...}: {
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      openFirewall = true;
      package = pkgs-unstable.ollama-cpu;
    };

    # Survive OOM kills (e.g. loading two models at once): keep the server
    # alive when only a runner is killed, and restart it if it dies itself
    systemd.services.ollama.serviceConfig = {
      OOMPolicy = "continue";
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
