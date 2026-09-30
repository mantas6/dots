{...}: {
  flake.modules.nixos."jobs-os-upgrade" = {lib, ...}: {
    system.autoUpgrade = {
      enable = true;

      persistent = false;

      flake = "github:mantas6/dots";
      flags = ["--accept-flake-config"];
      dates = lib.mkDefault "02:00";

      allowReboot = true;
      rebootWindow = {
        lower = "01:00";
        upper = "03:00";
      };
    };
  };
}
