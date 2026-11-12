{...}: {
  flake.modules.nixos."jobs-os-upgrade-desktop" = {
    system.autoUpgrade = {
      enable = true;
      persistent = true;

      flake = "github:mantas6/dots";
      dates = "07:00";
      randomizedDelaySec = "5min";
      operation = "boot";

      allowReboot = false;
    };
  };
}
