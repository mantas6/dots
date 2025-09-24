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

      systemd.user.services.sat-schedule = {
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
    })
  ];
}
