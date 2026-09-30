{...}: {
  flake.modules.nixos."jobs-os-upgrade-desktop" = {
    system.autoUpgrade = {
      enable = true;
      persistent = true;

      flake = "github:mantas6/dots";
      flags = ["--accept-flake-config"];
      dates = "09:00";
      operation = "boot";

      allowReboot = false;
    };
  };
}
