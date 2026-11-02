{...}: {
  flake.modules.nixos."collections-desktop" = {pkgs, ...}: let
    serviceName = "pass-pull";
  in {
    programs.gnupg = {
      agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-gtk2;
      };
    };

    environment.systemPackages = with pkgs; [
      pass
      # Use default_autotype for multi-line entries too, instead of hardcoded "user :tab pass"
      (rofi-pass.overrideAttrs (old: {
        postPatch =
          (old.postPatch or "")
          + ''
            substituteInPlace rofi-pass \
              --replace-fail '"''${USERNAME_field} :tab pass"' '"''${default_autotype}"'
          '';
      }))
      pwgen
    ];

    systemd.user.services.${serviceName} = {
      script = "${pkgs.pass}/bin/pass git pull";

      path = with pkgs; [
        pass
        gitMinimal
      ];

      environment = {
        PASSWORD_STORE_DIR = "%h/.local/share/password-store";
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
