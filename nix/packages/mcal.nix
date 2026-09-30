{...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: let
    rev = "c4a437dc770d86ff50b9152dc3d82d16dc142b79";
    shortRev = builtins.substring 0 7 rev;
    goPkgs = inputs'.nixpkgs-unstable.legacyPackages;
  in {
    packages.mcal = goPkgs.buildGoModule {
      pname = "mcal";
      version = "0-unstable-${shortRev}";

      src = pkgs.fetchFromGitHub {
        owner = "mantas6";
        repo = "mcal";
        inherit rev;
        hash = "sha256-h9DuKKw2aUEMwuafYs/39BN0NCXey1W8qZOWKNFkP+U=";
      };

      vendorHash = null;

      meta = {
        description = "Calendar with Lithuanian public holidays";
        homepage = "https://github.com/mantas6/mcal";
        mainProgram = "mcal";
      };
    };
  };
}
