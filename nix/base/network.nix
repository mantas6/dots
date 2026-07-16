{...}: {
  flake.modules.nixos.base = {...}: {
    networking = {
      usePredictableInterfaceNames = false;
    };
  };
}
