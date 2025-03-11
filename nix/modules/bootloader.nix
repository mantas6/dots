{
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 1;

    grub = {
      enable = true;
      efiSupport = true;
      useOSProber = true;

      devices = ["nodev"];
    };
  };
}
