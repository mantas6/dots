{
  description = "A very basic flake";

  inputs = {
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixpkgs.url = "nixpkgs/nixos-24.11";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    ...
  }: let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    pkgs = nixpkgs.legacyPackages.${system};
    pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
  in {
    formatter.x86_64-linux = pkgs.legacyPackages.x86_64-linux.alejandra;

    nixosConfigurations.ix = lib.nixosSystem {
      modules = [./nix/hosts/ix];

      specialArgs = {
        inherit pkgs-unstable;
      };
    };
  };
}
