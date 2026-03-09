{
  description = "My linux home systems";

  inputs = {
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgs-go.url = "github:NixOS/nixpkgs/d1d883129b193f0b495d75c148c2c3a7d95789a0";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xremap-flake.url = "github:xremap/nix-flake";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixpkgs-go,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    pkgs = nixpkgs.legacyPackages.${system};
    pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
    pkgs-go = nixpkgs-go.legacyPackages.${system};
    hosts = ["ix" "l4" "tp" "pd" "amd" "rt" "iso"];
  in {
    formatter.x86_64-linux = pkgs.alejandra;
    formatter.aarch64-linux = pkgs.alejandra;

    nixosConfigurations = builtins.listToAttrs (map (name: {
        inherit name;
        value = nixpkgs.lib.nixosSystem {
          modules = [./nix/hosts/${name}];

          specialArgs = {inherit inputs pkgs-unstable self;};
        };
      })
      hosts);

    packages.${system}.wolf = pkgs-go.buildGoModule {
      pname = "wolf";
      version = "0.1.0";
      src = ./opt/wolf/.;
      vendorHash = null;
    };

    apps.${system}.wolf = {
      type = "app";
      program = "${self.packages.${system}.wolf}/bin/wolf";
    };
  };
}
