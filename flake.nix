{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs?ref=nixos-24.11";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
  }: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    nixosConfigurations.ix = nixpkgs.lib.nixosSystem {
      modules = [./hosts/ix];
    };

    # nixosConfigurations.l4 = nixpkgs-stable.lib.nixosSystem {
    #   modules = [./hosts/l4];
    # };
  };
}
