{...}: {
  perSystem = {pkgs, ...}: {
    devShells.dash = pkgs.mkShell {
      packages = with pkgs; [tokei jq git];
    };
  };
}
