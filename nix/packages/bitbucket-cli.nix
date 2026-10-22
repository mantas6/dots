{...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: let
    rev = "a185437459957ffaa5d0afcb73b190a9f8c9e4f7";
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
        hash = "sha256-EtRKMEswAQoo2dHV0yqtkLctxOKXikqTUbS+iilMCn0=";
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
