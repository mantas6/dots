{...}: {
  flake.modules.nixos."collections-desktop" = {
    hardware.bluetooth.enable = true;

    services.udisks2.enable = true;

    programs.appimage = {
      enable = true;
      binfmt = true;
    };

    # org.freedesktop.secrets provider for Electron safeStorage (T3 Code etc.)
    services.gnome.gnome-keyring.enable = true;
    # Defaults to on with gnome-keyring; conflicts with programs.ssh.startAgent
    services.gnome.gcr-ssh-agent.enable = false;
  };
}
