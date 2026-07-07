{...}: {
  perSystem = {pkgs, ...}: {
    devShells.stats = pkgs.mkShell {
      packages = with pkgs; [tokei jq git];
    };
  };
}
