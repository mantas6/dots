{...}: {
  flake.modules.nixos."jobs-os-upgrade-desktop" = {
    system.autoUpgrade = {
      enable = true;
      persistent = true;

      flake = "github:mantas6/dots";
      dates = "09:00";
      operation = "boot";

      allowReboot = false;
    };
  };
}
