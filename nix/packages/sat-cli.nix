{...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: let
    rev = "33fa48593fad8f39593c26d5ad13ec303b50a4ae";
    shortRev = builtins.substring 0 7 rev;
    # sat-cli's go.mod requires go 1.26.7, which nixpkgs-unstable provides.
    goPkgs = inputs'.nixpkgs-unstable.legacyPackages;
  in {
    packages.sat = goPkgs.buildGoModule {
      pname = "sat";
      version = "0-unstable-${shortRev}";

      src = pkgs.fetchFromGitHub {
        owner = "mantas6";
        repo = "sat-cli";
        inherit rev;
        hash = "sha256-AJW4yZM6U2/cSpsjBF885tz+sV66HI/t6Tl6Z/l3tLQ=";
      };

      vendorHash = "sha256-KMunnWdq9rOMxBzEzNUiKzXY5AfEDxuuSjc/LrWTchE=";

      ldflags = ["-X main.version=${shortRev}"];

      nativeBuildInputs = [pkgs.makeWrapper];

      # Binary is named after the module path (sat-cli); rename to `sat` and
      # ensure the editor (article edit/new) and ssh runtime deps are reachable.
      postInstall = ''
        mv $out/bin/sat-cli $out/bin/sat
        wrapProgram $out/bin/sat \
          --suffix PATH : ${pkgs.lib.makeBinPath [goPkgs.neovim pkgs.openssh]}
      '';

      meta = {
        description = "Command-line client for Sat";
        homepage = "https://github.com/mantas6/sat-cli";
        mainProgram = "sat";
      };
    };
  };
}
