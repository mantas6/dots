{...}: {
  flake.modules.nixos."purposes-dashboard" = {
    self,
    config,
    lib,
    pkgs,
    ...
  }: let
    kmscon = config.services.kmscon;
    sat = self.packages.${pkgs.stdenv.hostPlatform.system}.sat;

    # Same content (and store path) as the kmscon module's own config dir.
    kmsconConfig = pkgs.writeTextFile {
      name = "kmscon-config";
      destination = "/kmscon.conf";
      text = kmscon.extraConfig;
    };

    # kmscon spawns this as root with a reset environment (TERM, COLORTERM,
    # XDG_SEAT, XDG_VTNR) and respawns it whenever it exits.
    dashboard = pkgs.writeShellApplication {
      name = "sat-dashboard";
      runtimeInputs = [pkgs.util-linux];
      text =
        /*
        bash
        */
        ''
          export SAT_URL_PATH=${config.age.secrets.sat-base-url.path}
          export SAT_TOKEN_PATH=${config.age.secrets.dashboard-token.path}
          runuser -u mantas -- ${lib.getExe sat} dashboard --follow || sleep 5
        '';
    };
  in {
    age.secrets = {
      sat-base-url.owner = "mantas";
      dashboard-token = {
        file = ./../../_lib/secrets/dashboard-token.age;
        owner = "mantas";
      };
    };

    console.font = "ter-732n";

    services.kmscon = {
      enable = true;
      hwRender = true;
      fonts = [
        {
          name = "AnonymicePro Nerd Font Mono";
          package = pkgs.nerd-fonts.anonymice;
        }
      ];
      extraConfig = ''
        font-engine=pango
        font-size=30
        dpms-timeout=0
      '';
    };

    boot.blacklistedKernelModules = ["psmouse"];

    # tty1 belongs to sat-dashboard instead of the stock kmscon console.
    systemd.targets.getty.wants = lib.mkForce [];

    # A dedicated unit (unlike kmsconvt@) gets restarted on switch whenever
    # the sat package or the kmscon config changes.
    systemd.services.sat-dashboard = {
      description = "Sat dashboard on tty1";
      after = ["systemd-user-sessions.service" "plymouth-quit-wait.service" "getty-pre.target" "kmsconvt@tty1.service"];
      before = ["getty.target"];
      wantedBy = ["getty.target"];
      conflicts = ["kmsconvt@tty1.service"];
      unitConfig.ConditionPathExists = "/dev/tty0";
      startLimitIntervalSec = 0;
      serviceConfig = {
        ExecStart = lib.concatStringsSep " " (
          ["${kmscon.package}/bin/kmscon" "--configdir" "${kmsconConfig}" "--vt=tty1" "--no-switchvt" "--login"]
          ++ lib.optional (kmscon.extraOptions != "") kmscon.extraOptions
          ++ ["--" (lib.getExe dashboard)]
        );
        Restart = "always";
        RestartSec = 2;
        UtmpIdentifier = "tty1";
        TTYPath = "/dev/tty1";
        TTYReset = true;
        TTYVHangup = true;
        TTYVTDisallocate = true;
      };
    };
  };
}
