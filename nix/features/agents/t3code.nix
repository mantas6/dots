{...}: {
  flake.modules.nixos."agents-t3code" = {
    lib,
    config,
    pkgs-unstable,
    ...
  }: let
    inherit (config.users.users.mantas) home;
    shell = lib.getExe config.users.users.mantas.shell;
    t3 = "${pkgs-unstable.t3code}/bin/t3";
  in {
    environment.systemPackages = [pkgs-unstable.t3code];

    systemd.user.services.t3code = {
      description = "T3 Code server";
      wantedBy = ["default.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.ConditionUser = "!root";
      environment = {
        SHELL = shell;
        T3CODE_HOME = "${home}/.local/share/t3";
      };
      serviceConfig = {
        ExecStart = "${shell} -lc 'exec ${t3} serve --mode web --port 3773 --host 0.0.0.0 --no-browser'";
        WorkingDirectory = "%h";
        Restart = "always";
        RestartSec = 2;
        NoNewPrivileges = true;
        # PrivateTmp = true;
      };
    };
  };
}
