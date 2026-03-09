{
  lib,
  config,
  pkgs,
  ...
}: let
  name = "services.sat-backups";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      systemd.user.services.sat-backups = {
        script = "/home/mantas/Offload/Sat/run";

        path = with pkgs; [
          openssl
          bash
          jq
          curl
        ];

        after = ["network-online.target"];
        wants = ["network-online.target"];

        serviceConfig = {
          Type = "oneshot";
        };

        startAt = ["03:00" "09:00"];
      };

      systemd.user.timers.sat-backups = {
        timerConfig = {
          Persistent = true;
        };
      };
    })
  ];
}
