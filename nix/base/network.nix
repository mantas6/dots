{...}: {
  flake.modules.nixos.base = {lib, ...}: {
    networking = {
      usePredictableInterfaceNames = false;
      firewall.enable = lib.mkDefault true;
    };
  };
}
