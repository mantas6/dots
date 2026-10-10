{
  lib,
  pkgs,
  ...
}: let
  prepare = pkgs.writeShellApplication {
    name = "prepare-windows11";
    runtimeInputs = [pkgs.coreutils pkgs.openssl];
    text = ''
      umask 077
      credentials="$STATE_DIRECTORY/credentials.env"
      storage="$STATE_DIRECTORY/storage"

      if [[ ! -s "$credentials" ]]; then
        # Never invent new credentials for an existing installation.
        if [[ -d "$storage" ]]; then
          printf '%s\n' 'Windows storage exists but credentials are missing; restore credentials.env from backup.' >&2
          exit 1
        fi
        temporary=$(mktemp "$STATE_DIRECTORY/.credentials.XXXXXX")
        trap 'rm -f "$temporary"' EXIT
        printf 'PASSWORD=%s\n' "$(openssl rand -hex 24)" > "$temporary"
        mv "$temporary" "$credentials"
      fi

      chmod 600 "$credentials"
      mkdir -p "$storage"
      chmod 700 "$storage"
    '';
  };
in {
  boot.kernelModules = ["kvm-intel" "tun"];
  virtualisation.docker.enable = true;

  systemd.services.windows11-prepare = {
    description = "Prepare persistent Windows 11 storage and installation credentials";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "windows11";
      StateDirectoryMode = "0700";
      UMask = "0077";
      ExecStart = lib.getExe prepare;
    };
  };

  virtualisation.oci-containers.containers.windows11 = {
    # Dockur packages QEMU/KVM and the unattended installer; this is a VM,
    # not Windows sharing the host kernel. Pin the installer, not a mutable tag.
    image = "docker.io/dockurr/windows@sha256:0cff9eb0e7aee9953e55bc682852ca4fdca233145a58ae1ec94f0b0c01a2ed30";
    autoStart = true;
    environment = {
      VERSION = "11";
      RAM_SIZE = "8G";
      CPU_CORES = "2";
      DISK_SIZE = "64G";
      DISK_FMT = "qcow2";
      BOOT_MODE = "windows_secure";
      KVM = "Y";
      RAM_CHECK = "Y";
      USERNAME = "mantas";
      AUTOLOGIN = "N";
      SAMBA = "N";
      TIMEOUT = "105";
    };
    environmentFiles = ["/var/lib/windows11/credentials.env"];
    volumes = ["/var/lib/windows11/storage:/storage"];
    # The browser console is otherwise unauthenticated. Use an SSH tunnel
    # for both it and RDP instead of exposing either to the LAN or Internet.
    ports = [
      "127.0.0.1:8006:8006/tcp"
      "127.0.0.1:3389:3389/tcp"
    ];
    extraOptions = [
      "--device=/dev/kvm"
      "--device=/dev/net/tun"
      "--cap-add=NET_ADMIN"
      "--stop-timeout=120"
    ];
  };

  systemd.services.docker-windows11 = {
    requires = ["windows11-prepare.service"];
    after = ["windows11-prepare.service"];
    preStart = lib.mkBefore ''
      if [[ ! -c /dev/kvm || ! -c /dev/net/tun ]]; then
        echo 'Windows 11 requires /dev/kvm and /dev/net/tun; enable Intel VT-x in firmware.' >&2
        exit 1
      fi
    '';
    # Longer than Docker's 120-second grace period for guest ACPI shutdown.
    serviceConfig.TimeoutStopSec = lib.mkForce 150;
  };
}
