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
    hermes-agent.url = "github:NousResearch/hermes-agent";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} (let
      system = "x86_64-linux";
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
      hosts = [
        "ix"
        "l4"
        "tp"
        "pd"
        "a5"
        "rt"
        "mt"
        "iso"
      ];
    in {
      systems = [system];

      flake.nixosConfigurations = builtins.listToAttrs (map (name: {
          inherit name;
          value = nixpkgs.lib.nixosSystem {
            modules = [
              (inputs.import-tree ./nix/modules)
              (inputs.import-tree ./nix/hosts/${name})
            ];

            specialArgs = {inherit inputs pkgs-unstable self;};
          };
        })
        hosts);

      perSystem = {
        config,
        pkgs,
        inputs',
        ...
      }: {
        formatter = pkgs.alejandra;

        packages.wolf = inputs'.nixpkgs-go.legacyPackages.buildGoModule {
          pname = "wolf";
          version = "0.1.0";
          src = ./opt/wolf/.;
          vendorHash = null;
        };

        apps.wolf = {
          type = "app";
          program = "${config.packages.wolf}/bin/wolf";
          meta.description = "HTTP server that sends Wake-on-LAN packets to hosts resolved from dnsmasq leases";
        };
      };
    });
}
