{
  description = "A very basic flake";

  inputs = {
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "nixpkgs/nixos-25.05";
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
    # hosts = [
    #   "iso"
    #   "ix"
    #   "amd"
    #   "l4"
    #   "rt"
    #   "tp"
    #   "pd"
    # ];
  in {
    formatter.x86_64-linux = pkgs.alejandra;
    formatter.aarch64-linux = pkgs.alejandra;
    # nixosConfigurations = builtins.listToAttrs (map (name: {
    #     ${name} = {
    #       modules = [./nix/hosts/${name}];
    #
    #       specialArgs = {
    #         inherit inputs;
    #         inherit pkgs-unstable;
    #         inherit self;
    #       };
    #     };
    #   })
    #   hosts);

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
        inherit self;
      };
    };

    nixosConfigurations.amd = nixpkgs.lib.nixosSystem {
      modules = [
        ./nix/hosts/amd
      ];

      specialArgs = {
        inherit inputs;
        inherit pkgs-unstable;
        inherit self;
      };
    };

    nixosConfigurations.l4 = nixpkgs.lib.nixosSystem {
      modules = [
        ./nix/hosts/l4
      ];

      specialArgs = {
        inherit inputs;
        inherit pkgs-unstable;
        inherit self;
      };
    };

    nixosConfigurations.rt = nixpkgs.lib.nixosSystem {
      modules = [
        ./nix/hosts/rt
      ];

      specialArgs = {
        inherit inputs;
        inherit pkgs-unstable;
        inherit self;
      };
    };

    nixosConfigurations.tp = nixpkgs.lib.nixosSystem {
      modules = [
        ./nix/hosts/tp
      ];

      specialArgs = {
        inherit inputs;
        inherit pkgs-unstable;
        inherit self;
      };
    };

    nixosConfigurations.pd = nixpkgs.lib.nixosSystem {
      modules = [
        ./nix/hosts/pd
      ];

      specialArgs = {
        inherit inputs;
        inherit pkgs-unstable;
        inherit self;
      };
    };

    packages.${system}.wolf = pkgs-go.buildGoModule {
      pname = "wolf";
      version = "0.1.0";
      src = ./lib/wolf/.;
      vendorHash = null;
    };

    apps.${system}.wolf = {
      type = "app";
      program = "${self.packages.${system}.wolf}/bin/wolf";
    };
  };
}
