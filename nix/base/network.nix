{...}: {
  flake.nixosModules.base = {lib, ...}: {
    networking = {
      usePredictableInterfaceNames = false;
      firewall.enable = lib.mkDefault false;
    };
  };
}
