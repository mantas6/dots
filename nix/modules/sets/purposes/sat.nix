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

      systemd.services.sat-schedule = {
        script = "php %h/Sat/current schedule:run >> /dev/null 2>&1";

        path = phpEnv;

        serviceConfig = {
          Type = "oneshot";
          User = userName;
        };

        restartIfChanged = false;
        unitConfig.X-StopOnRemoval = false;

        after = ["network-online.target"];
        wants = ["network-online.target"];

        startAt = "minutely";
      };

      systemd.services.sat-octane = {
        script = "php artisan octane:start --workers=8";

        path = phpEnv;

        serviceConfig = {
          User = userName;
        };

        after = ["network-online.target"];
        wants = ["network-online.target"];
      };

      systemd.services.sat-horizon = {
        script = "php artisan horizon";

        path = phpEnv;

        serviceConfig = {
          User = userName;
          TimeoutStopSec = "3600s";
        };

        after = ["network-online.target"];
        wants = ["network-online.target"];
      };
    })
  ];
}
