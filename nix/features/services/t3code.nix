{...}: {
  flake.modules.nixos."services-t3code" = {
    pkgs,
    pkgs-unstable,
    lib,
    inputs,
    ...
  }: let
    pkgs-unstable-unfree = import inputs.nixpkgs-unstable {
      system = pkgs-unstable.stdenv.hostPlatform.system;
      config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) ["claude-code"];
    };
  in {
    systemd.user.services.t3code = {
      description = "T3 Code server";
      wantedBy = ["default.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.ConditionUser = "!root";
      path = [
        pkgs-unstable.codex
        pkgs-unstable.opencode
        pkgs-unstable.git
        pkgs-unstable.gh
        pkgs-unstable.nodejs_24
        pkgs-unstable-unfree.claude-code
        pkgs.bash
        pkgs.coreutils
      ];
      serviceConfig = {
        ExecStart = "${pkgs-unstable.t3code}/bin/t3 serve --mode web --host 0.0.0.0 --no-browser";
        WorkingDirectory = "%h";
        Restart = "always";
        RestartSec = 2;
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };
  };
}
