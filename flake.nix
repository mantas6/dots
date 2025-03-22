{
  description = "A very basic flake";

  inputs = {
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixpkgs.url = "nixpkgs/nixos-24.11";

    disko = {
      url = "nix-community/disko";
      follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    disko,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
  in {
    formatter.x86_64-linux = pkgs.alejandra;

    nixosConfigurations.ix = nixpkgs.lib.nixosSystem {
      modules = [./nix/hosts/ix];

      specialArgs = {
        inherit pkgs-unstable;
      };
    };

    # nixosConfigurations.a5 = nixpkgs.lib.nixosSystem {
    #   modules = [
    #       disko.nixosModules.disko
    #       ./nix/hosts/a5
    #     ];
    #
    #   specialArgs = {
    #     inherit pkgs-unstable;
    #   };
    # };
  };
}
