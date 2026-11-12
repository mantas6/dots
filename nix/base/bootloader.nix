{...}: {
  flake.modules.nixos.base = {lib, ...}: {
    boot.loader = {
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        useOSProber = lib.mkDefault false;
        memtest86.enable = lib.mkDefault true;
      };

      timeout = lib.mkDefault 1;

      efi.canTouchEfiVariables = true;
    };
  };
}
