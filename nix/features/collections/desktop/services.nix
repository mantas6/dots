{...}: {
  flake.modules.nixos."collections-desktop" = {
    hardware.bluetooth.enable = true;

    services.udisks2.enable = true;
  };
}
