# Minimal NVIDIA driver setup for headless CUDA hosts (no desktop)
{...}: {
  flake.modules.nixos."hardware-nvidia-headless" = {config, ...}: {
    nixpkgs.config.allowUnfreePackages = [
      "nvidia-x11"
      "nvidia-kernel-modules"
    ];

    # Enables the nvidia driver module without starting X
    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
      # Proprietary kernel module works on every generation; set to true for
      # Turing or newer cards if the open module is preferred
      open = false;

      # Keeps the GPU initialised and device nodes present without a display
      nvidiaPersistenced = true;

      nvidiaSettings = false;

      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
