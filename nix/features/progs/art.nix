{...}: {
  flake.modules.nixos."progs-art" = {
    lib,
    config,
    pkgs,
    ...
  }: {
    environment.systemPackages = with pkgs; [
      gimp
      natron
      ffmpeg
      kdePackages.kdenlive
      audacity
    ];
  };
}
