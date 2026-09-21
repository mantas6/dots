{...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: let
    rev = "c3eb04cb615dceb1f51ac5b2572d4070dc994249";
    shortRev = builtins.substring 0 7 rev;
    goPkgs = inputs'.nixpkgs-unstable.legacyPackages;
  in {
    packages.bh = goPkgs.buildGoModule {
      pname = "bh";
      version = "0-unstable-${shortRev}";

      src = pkgs.fetchFromGitHub {
        owner = "mantas6";
        repo = "bh";
        inherit rev;
        hash = "sha256-tFTELr728EXK27RArz6XMIa4sInmne2ib813gdv4SaU=";
      };

      vendorHash = "sha256-W9zZeMO5Gc9BpiMbN5OtgL5WRo3wBw/Pm3JXv85lxgI=";

      subPackages = ["cmd/bh"];

      ldflags = ["-X main.version=${shortRev}"];

      meta = {
        description = "Command-line client for Bitbucket";
        homepage = "https://github.com/mantas6/bh";
        mainProgram = "bh";
      };
    };
  };

  flake.modules.nixos."collections-develop" = {
    pkgs,
    self,
    ...
  }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.bh
    ];
  };
}
