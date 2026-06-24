{
  lib,
  config,
  ...
}: let
  name = "quirks.prevent-sleep";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      systemd.sleep.settings.Sleep = {
        AllowSuspend = false;
        AllowHibernation = false;
        AllowHybridSleep = false;
        AllowSuspendThenHibernate = false;
      };
    })
  ];
}
