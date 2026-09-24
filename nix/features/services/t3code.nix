{...}: {
  flake.modules.nixos."services-t3code" = {
    lib,
    config,
    pkgs-unstable,
    ...
  }: {
    systemd.user.services.t3code = {
      description = "T3 Code server";
      wantedBy = ["default.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.ConditionUser = "!root";
      environment.SHELL = lib.getExe config.users.users.mantas.shell;
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
