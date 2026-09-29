{...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: let
    rev = "debbc2dcf92f6f08c89c976880dd04b39f791e17";
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
        hash = "sha256-35RlwK9+rsEhI8Q0PPkZA2JKT0nB9ZBjURRF6Mgfvqk=";
      };

      vendorHash = "sha256-5Jf9J0G408h3yIzZ8y99SVpfIfm9E0ivgtonMZMy68U=";

      subPackages = ["cmd/sat"];

      ldflags = ["-X main.version=${shortRev}"];

      nativeBuildInputs = [pkgs.makeWrapper];

      # Ensure the editor (article edit/new) and ssh runtime deps are reachable.
      postInstall = ''
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
