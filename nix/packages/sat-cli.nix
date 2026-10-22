{...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: let
    rev = "f2b91cacbfa33537a63465165926dce0bf4eb838";
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
        hash = "sha256-4s4FT3AyLj4KakN/x42lTf7ggEBh6ca7HROc74JxIAk=";
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
