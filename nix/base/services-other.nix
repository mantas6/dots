{...}: {
  flake.nixosModules.base = {...}: {
    services.fstrim.enable = true;
  };
}
