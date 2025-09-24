{
  description = "A very basic flake";

  inputs = {
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "nixpkgs/nixos-25.05";

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
    formatter.aarch64-linux = pkgs.alejandra;

    nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
      modules = [./nix/hosts/iso];

      specialArgs = {
        inherit inputs;
      };
    };

    nixosConfigurations.ix = nixpkgs.lib.nixosSystem {
      modules = [./nix/hosts/ix];

      specialArgs = {
        inherit inputs;
        inherit pkgs-unstable;
      };
    };

    nixosConfigurations.utm = nixpkgs.lib.nixosSystem {
      modules = [./nix/hosts/utm];

      system = "aarch64-linux";

      specialArgs = {
        pkgs-unstable = nixpkgs-unstable.legacyPackages.aarch64-linux;
        inherit inputs;
      };
    };

    nixosConfigurations.amd = nixpkgs.lib.nixosSystem {
      modules = [
        ./nix/hosts/amd
      ];

      specialArgs = {
        inherit inputs;
        inherit pkgs-unstable;
      };
    };

    nixosConfigurations.l4 = nixpkgs.lib.nixosSystem {
      modules = [
        ./nix/hosts/l4
      ];

      specialArgs = {
        inherit inputs;
        inherit pkgs-unstable;
      };
    };

    nixosConfigurations.rt = nixpkgs.lib.nixosSystem {
      modules = [
        ./nix/hosts/rt
      ];

      specialArgs = {
        inherit inputs;
        inherit pkgs-unstable;
      };
    };

    nixosConfigurations.tp = nixpkgs.lib.nixosSystem {
      modules = [
        ./nix/hosts/tp
      ];

      specialArgs = {
        inherit inputs;
        inherit pkgs-unstable;
      };
    };

    nixosConfigurations.pd = nixpkgs.lib.nixosSystem {
      modules = [
        ./nix/hosts/pd
      ];

      specialArgs = {
        inherit inputs;
        inherit pkgs-unstable;
      };
    };
  };
}
