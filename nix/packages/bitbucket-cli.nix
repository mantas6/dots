{...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: let
    rev = "e1de03a3af63d0f1e77df9f63841339015719641";
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
        hash = "sha256-gEd2N2n5kLjxYQJVW5wd5V1EGiFouexrcdVMLzhOjp4=";
      };

      vendorHash = "sha256-EqtrbagCH6DaiRDhfZP+EUeOSERAgIXEsrL1WPsiLqo=";

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
