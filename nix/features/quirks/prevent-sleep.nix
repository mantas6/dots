{...}: {
  flake.modules.nixos."quirks-prevent-sleep" = {
    lib,
    config,
    ...
  }: {
    systemd.sleep.settings.Sleep = {
      AllowSuspend = false;
      AllowHibernation = false;
      AllowHybridSleep = false;
      AllowSuspendThenHibernate = false;
    };
  };
}
