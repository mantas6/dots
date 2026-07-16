{...}: {
  flake.modules.nixos.base = {...}: {
    services.fstrim.enable = true;
  };
}
