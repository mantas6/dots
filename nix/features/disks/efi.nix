{...}: {
  flake.modules.nixos."disks-efi" = {lib, ...}: {
    # GRUB reads kernels from /boot on the ext4 root, so the ESP only holds the GRUB EFI binary
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    disko.devices = {
      disk = {
        main-disk = {
          device = lib.mkDefault "/dev/sda";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = "512M";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  extraArgs = ["-F" "32"];
                  mountpoint = "/boot/efi";
                  mountOptions = ["umask=0077"];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
