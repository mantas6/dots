{
  lib,
  config,
  pkgs,
  ...
}: let
  name = "purposes.sat";

  userName = "mantas";

  phpEnv = with pkgs; [
    php84
    php84Packages.composer
    # php84Extensions.mysql
    php84Extensions.mysqli
    php84Extensions.mbstring
    php84Extensions.xml
    php84Extensions.bcmath
    php84Extensions.curl
    # php84Extensions.cli
    php84Extensions.zip
    php84Extensions.intl
  ];

  defaultServiceOptions = {
    path = phpEnv;

    serviceConfig = {
      User = userName;
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
        virtualHosts."myapp.example.com".extraConfig = ''
          reverse_proxy localhost:8000
        '';
      };

      services.mysql = {
        enable = true;
        package = pkgs.mariadb;
      };

      systemd.services.sat-schedule = defaultServiceOptions // {
        script = "php %h/Sat/current schedule:run >> /dev/null 2>&1";

        serviceConfig = {
          Type = "oneshot";
        };

        restartIfChanged = false;
        unitConfig.X-StopOnRemoval = false;

        startAt = "minutely";
      };

      systemd.services.sat-octane = defaultServiceOptions // {
        script = "php artisan octane:start --workers=8";
      };

      systemd.services.sat-horizon = defaultServiceOptions // {
        script = "php artisan horizon";

        serviceConfig = {
          TimeoutStopSec = "3600s";
        };
      };
    })
  ];
}
