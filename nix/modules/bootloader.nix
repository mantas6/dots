{
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
    };

    timeout = 1;

    efi.canTouchEfiVariables = true;
  };
}
