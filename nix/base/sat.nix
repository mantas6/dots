# sat: Go CLI client for Satellite, built from github.com/mantas6/sat-cli
{...}: {
  flake.modules.nixos.base = {
    pkgs,
    inputs,
    ...
  }: let
    rev = "023bd041db552a1b8522fbfbe318cecbb34e83a3";
    # sat-cli's go.mod requires go 1.26.7, which nixpkgs-unstable provides.
    goPkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    sat = goPkgs.buildGoModule {
      pname = "sat";
      version = "0-unstable-${builtins.substring 0 7 rev}";

      src = pkgs.fetchFromGitHub {
        owner = "mantas6";
        repo = "sat-cli";
        inherit rev;
        hash = "sha256-DtMx8bOMHW4BKhwcDyOSO/tqtEPK3ZtkyTBs03mlZs0=";
      };

      vendorHash = "sha256-KMunnWdq9rOMxBzEzNUiKzXY5AfEDxuuSjc/LrWTchE=";

      ldflags = ["-s" "-w" "-X main.version=${builtins.substring 0 7 rev}"];

      nativeBuildInputs = [pkgs.makeWrapper];

      # Binary is named after the module path (sat-cli); rename to `sat` and
      # ensure the editor (article edit/new) and ssh runtime deps are reachable.
      postInstall = ''
        mv $out/bin/sat-cli $out/bin/sat
        wrapProgram $out/bin/sat \
          --suffix PATH : ${pkgs.lib.makeBinPath [pkgs.neovim pkgs.openssh]}
      '';

      meta = {
        description = "Command-line client for Satellite";
        homepage = "https://github.com/mantas6/sat-cli";
        mainProgram = "sat";
      };
    };
  in {
    environment.systemPackages = [sat];
  };
}
