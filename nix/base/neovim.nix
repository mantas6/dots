{...}: {
  flake.modules.nixos.base = {
    lib,
    pkgs-unstable,
    ...
  }: {
    options.features.neovim.package = lib.mkOption {
      type = lib.types.package;
      default = pkgs-unstable.neovim;
      defaultText = lib.literalExpression "pkgs-unstable.neovim";
      description = "Neovim package used system-wide. Unstable by default; constrained hosts pick stable to avoid a second nixpkgs tree.";
    };
  };
}
