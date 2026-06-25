{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.base = {pkgs, ...}: {
    imports = [
      inputs.disko.nixosModules.disko
      inputs.agenix.nixosModules.default
    ];

    _module.args = {
      inherit inputs self;
      pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    };
  };
}
