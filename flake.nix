{
  description = "A very basic flake";

  inputs = {
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "nixpkgs/nixos-24.11";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xremap-flake.url = "github:xremap/nix-flake";
  };

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
  in {
    formatter.x86_64-linux = pkgs.alejandra;

    nixosConfigurations.ix = nixpkgs.lib.nixosSystem {
      modules = [./nix/hosts/ix];

      specialArgs = {
        inherit inputs;
        inherit pkgs-unstable;
      };
    };

    # nixosConfigurations.a5 = nixpkgs.lib.nixosSystem {
    #   modules = [
    #       ./nix/hosts/a5
    #     ];
    #
    #   specialArgs = {
    #     inherit inputs;
    #     inherit pkgs-unstable;
    #   };
    # };
  };
}
