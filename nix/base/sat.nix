{...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: let
    rev = "422008eaa78d8cffec34d1a291905fa52eb1d8d7";
    # sat-cli's go.mod requires go 1.26.7, which nixpkgs-unstable provides.
    goPkgs = inputs'.nixpkgs-unstable.legacyPackages;
  in {
    packages.sat = goPkgs.buildGoModule {
      pname = "sat";
      version = "0-unstable-${builtins.substring 0 7 rev}";

      src = pkgs.fetchFromGitHub {
        owner = "mantas6";
        repo = "sat-cli";
        inherit rev;
        hash = "sha256-8ryi0y2p8FQTL23buh9MIriWsK8Zac3CJUfnBdJlSSw=";
      };

      vendorHash = "sha256-KMunnWdq9rOMxBzEzNUiKzXY5AfEDxuuSjc/LrWTchE=";

      ldflags = ["-X main.version=${builtins.substring 0 7 rev}"];

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

  flake.modules.nixos.base = {
    pkgs,
    self,
    ...
  }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.sat
    ];
  };
}
