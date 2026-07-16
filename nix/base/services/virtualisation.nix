{...}: {
  flake.modules.nixos.base = {...}: {
    virtualisation.oci-containers.backend = "docker";
  };
}
