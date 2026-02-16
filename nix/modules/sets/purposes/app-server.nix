{
  pkgs,
  lib,
  config,
  ...
}: let
  name = "purposes.app-server";

  userName = "mantas";

  phpConfigured = pkgs.php85.buildEnv {
    extensions = {
      enabled,
      all,
    }:
      enabled
      ++ (with all; [
        pdo
        pdo_mysql
        pdo_sqlite
        mbstring
        # xml
        bcmath
        curl
        zip
        intl
      ]);
    # extraConfig = ''
    # '';
  };

  phpEnv = with pkgs; [
    phpConfigured
    phpConfigured.packages.composer
  ];

  defaultServiceOptions = {
    path = phpEnv;

    serviceConfig = {
      User = userName;
      WorkingDirectory = "%h/Sat/current";
      Restart = "always";
      RestartSec = 1;
    };

    after = ["network-online.target"];
    wants = ["network-online.target"];
  };
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      environment.systemPackages = phpEnv;

      services.caddy = {
        enable = true;

        # Example: reverse proxy for myapp.example.com → localhost:8000
        virtualHosts."http://localhost:8080".extraConfig = ''
          reverse_proxy localhost:8000 {
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };

      services.mysql = {
        enable = true;
        package = pkgs.mariadb;
      };

      systemd.services.sat-schedule =
        defaultServiceOptions
        // {
          script = "php artisan schedule:run >> /dev/null 2>&1";

          serviceConfig = {
            Type = "oneshot";
          };

          restartIfChanged = false;
          unitConfig.X-StopOnRemoval = false;

          startAt = "minutely";
        };

      systemd.services.sat-octane =
        defaultServiceOptions
        // {
          script = "php artisan octane:start --workers=8";
        };

      systemd.services.sat-horizon =
        defaultServiceOptions
        // {
          script = "php artisan horizon";

          serviceConfig = {
            TimeoutStopSec = "3600s";
          };
        };
    })
  ];
}
