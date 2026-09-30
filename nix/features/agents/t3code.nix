{...}: {
  flake.modules.nixos."agents-t3code" = {
    lib,
    config,
    pkgs-unstable,
    ...
  }: let
    zsh = lib.getExe config.users.users.${config.features.serviceUser}.shell;
    t3 = "${pkgs-unstable.t3code}/bin/t3";
  in {
    # The port is pinned so that a clash (e.g. another user's instance) fails
    # loudly instead of t3 silently picking a random port.
    systemd.user.services.t3code = {
      description = "T3 Code server";
      wantedBy = ["default.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.ConditionUser = config.features.serviceUser;
      environment.SHELL = zsh;
      serviceConfig = {
        ExecStart = "${zsh} -lc 'exec ${t3} serve --mode web --host 0.0.0.0 --port 3773 --no-browser'";
        WorkingDirectory = "%h";
        Restart = "always";
        RestartSec = 2;
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };
  };
}
