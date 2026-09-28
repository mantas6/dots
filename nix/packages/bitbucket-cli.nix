{inputs, ...}: {
  perSystem = {inputs', ...}: let
    inherit (inputs.bh) shortRev;
    goPkgs = inputs'.nixpkgs-unstable.legacyPackages;
  in {
    packages.bh = goPkgs.buildGoModule {
      pname = "bh";
      version = "0-unstable-${shortRev}";

      src = inputs.bh;

      # Must be bumped manually if go.mod/go.sum change upstream after `nix flake update`.
      vendorHash = "sha256-W9zZeMO5Gc9BpiMbN5OtgL5WRo3wBw/Pm3JXv85lxgI=";

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
