{...}: {
  flake.nixosModules.base = {...}: {
    networking = {
      usePredictableInterfaceNames = false;
    };
  };
}
