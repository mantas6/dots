{...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: let
    rev = "3b05e910cd35886ac615fc46caa635ca9deb7067";
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
        hash = "sha256-zciiZgQ8Y0V9WB4bcQoqraCjybExNO/uM2bRlWf0f+I=";
      };

      vendorHash = "sha256-55NYpIQvNpY6q/7Y8GZuh6IvknT7pvYHj2oJNw9eRHU=";

      subPackages = ["cmd/bh"];

      ldflags = ["-X main.version=${shortRev}"];

      meta = {
        description = "Command-line client for Bitbucket";
        homepage = "https://github.com/mantas6/bh";
        mainProgram = "bh";
      };
    };
  };
}
