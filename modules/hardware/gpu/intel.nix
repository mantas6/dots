{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf (config.gpu.type == "intel") {
    hardware.opengl = {
      enable = true;
      # extraPackages = with pkgs; [
      #   vpl-gpu-rt # for newer GPUs on NixOS >24.05 or unstable
      #   # onevpl-intel-gpu  # for newer GPUs on NixOS <= 24.05
      #   # intel-media-sdk   # for older GPUs
      # ];
    };
  };
}
