{...}: {
  flake.modules.nixos."agents-t3code" = {
    lib,
    config,
    pkgs,
    pkgs-unstable,
    ...
  }: let
    zsh = lib.getExe config.users.users.mantas.shell;
    t3 = "${pkgs-unstable.t3code}/bin/t3";
  in {
    environment.systemPackages = [pkgs-unstable.t3code];

    # T3's browser downloads a generic chrome-headless-shell binary, run it via nix-ld
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        glib
        nspr
        nss
        at-spi2-core
        dbus
        libx11
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libxcb
        libgbm
        expat
        libxkbcommon
        systemdLibs
        alsa-lib
      ];
    };

    systemd.user.services.t3code = {
      description = "T3 Code server";
      wantedBy = ["default.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.ConditionUser = "!root";
      environment = {
        SHELL = zsh;
        T3CODE_HOME = "%h/.local/share/t3";
      };
      serviceConfig = {
        ExecStart = "${zsh} -lc 'exec ${t3} serve --mode web --port 3773 --host 0.0.0.0 --no-browser'";
        WorkingDirectory = "%h";
        Restart = "always";
        RestartSec = 2;
        NoNewPrivileges = true;
        # PrivateTmp = true;
      };
    };
  };
}
