{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.base = {pkgs, ...}: {
    imports = [inputs.disko.nixosModules.disko];

    _module.args = {
      inherit inputs self;
      pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    };
  };
}
