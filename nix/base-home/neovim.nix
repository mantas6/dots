{...}: {
  flake.modules.nixos.base-home = {pkgs-unstable, ...}: {
    environment.systemPackages = [pkgs-unstable.neovim];
  };
}
