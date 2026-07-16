{...}: {
  flake.modules.nixos."hardware-amd" = {
    lib,
    config,
    ...
  }: {
    hardware.graphics = {
      enable = true;
      # enable32Bit = true;
    };
  };
}
