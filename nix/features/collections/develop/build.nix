{...}: {
  flake.modules.nixos."collections-develop" = {
    pkgs-unstable,
    ...
  }: let
    bh = pkgs-unstable.buildGoModule {
      pname = "bh";
      version = "0-unstable-2026-09-10";
      src = pkgs-unstable.fetchFromGitHub {
        owner = "mantas6";
        repo = "bh";
        rev = "c3eb04cb615dceb1f51ac5b2572d4070dc994249";
        hash = "sha256-tFTELr728EXK27RArz6XMIa4sInmne2ib813gdv4SaU=";
      };
      vendorHash = "sha256-W9zZeMO5Gc9BpiMbN5OtgL5WRo3wBw/Pm3JXv85lxgI=";
      subPackages = ["cmd/bh"];
      ldflags = ["-s" "-w" "-X main.version=0-unstable-2026-09-10"];
    };
  in {
    environment.systemPackages = [bh];
  };
}
