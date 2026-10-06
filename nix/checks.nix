{...}: {
  perSystem = {pkgs, ...}: {
    checks.actionlint =
      pkgs.runCommand "actionlint" {
        nativeBuildInputs = [pkgs.actionlint];
        src = ../.;
      } ''
        cd "$src"
        actionlint .github/workflows/*.yml
        touch "$out"
      '';
  };
}
