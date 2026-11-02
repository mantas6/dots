{...}: {
  flake.modules.nixos."collections-develop" = {inputs, ...}: {
    # `nix run unstable#<app>` pinned to the locked nixpkgs-unstable input
    nix.registry.unstable.flake = inputs.nixpkgs-unstable;
  };
}
