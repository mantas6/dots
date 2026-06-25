{...}: {
  flake.nixosModules.base = {...}: {
    virtualisation.oci-containers.backend = "docker";
  };
}
