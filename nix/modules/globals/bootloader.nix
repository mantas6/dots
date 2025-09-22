{lib, ...}: {
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = lib.mkDefault false;
    };

    timeout = 1;

    efi.canTouchEfiVariables = true;
  };
}
