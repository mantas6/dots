{...}: {
  flake.modules.nixos."jobs-os-upgrade" = {lib, ...}: {
    system.autoUpgrade = {
      enable = true;

      persistent = false;

      flake = "github:mantas6/dots";
      dates = lib.mkDefault "02:00";
      randomizedDelaySec = "5min";

      allowReboot = true;
      rebootWindow = {
        lower = "01:00";
        upper = "03:00";
      };
    };
  };
}
