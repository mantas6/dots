{...}: {
  flake.modules.nixos."jobs-os-upgrade-desktop" = {lib, ...}: {
    system.autoUpgrade = {
      enable = true;
      persistent = true;

      flake = "github:mantas6/dots";
      dates = "07:00";
      randomizedDelaySec = lib.mkDefault "5min";
      operation = "boot";

      allowReboot = false;
    };
  };
}
