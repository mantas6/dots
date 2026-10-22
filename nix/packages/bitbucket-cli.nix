{...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: let
    rev = "dc81dd31a37e009a7ebcf96b91e41230510605d9";
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
        hash = "sha256-H0JIRxUJDTUeT+Fqj0lNGRuDGtvxZvxNj6zw3vaf8Z0=";
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
