{...}: {
  flake.modules.nixos."collections-desktop" = {
    config,
    pkgs,
    ...
  }: let
    serviceName = "pass-pull";
    storeDir = "%h/.local/share/password-store";
  in {
    programs.gnupg = {
      agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-gtk2;
      };
    };

    environment.systemPackages = with pkgs; [
      pass
      rofi-pass
      pwgen
    ];

    # Provide org.freedesktop.secrets on the session bus (Electron safeStorage etc.)
    # with pass as the backend; secrets land under secret_service/ in the store.
    services.passSecretService.enable = true;

    systemd.user.services."dbus-org.freedesktop.secrets".serviceConfig.ExecStart = [
      ""
      "${config.services.passSecretService.package}/bin/pass_secret_service --path ${storeDir}"
    ];

    systemd.user.services.${serviceName} = {
      script = "${pkgs.pass}/bin/pass git pull";

      path = with pkgs; [
        pass
        gitMinimal
      ];

      environment = {
        PASSWORD_STORE_DIR = storeDir;
      };

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";
      };

      startAt = "daily";
    };

    systemd.user.timers.${serviceName} = {
      timerConfig = {
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
