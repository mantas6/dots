{self, ...}: {
  perSystem = {pkgs, ...}: let
    config = self.nixosConfigurations.rt.config;
    vm = config.virtualisation.oci-containers.containers.windows11;
    service = config.systemd.services.docker-windows11;
    prepare = config.systemd.services.windows11-prepare.serviceConfig.ExecStart;
  in {
    checks.rt-windows11 = assert vm.environment.VERSION == "11";
    assert vm.environment.RAM_SIZE == "8G";
    assert vm.environment.KVM == "Y";
    assert vm.environment.BOOT_MODE == "windows_secure";
    assert vm.environment.AUTOLOGIN == "N";
    assert !(vm.environment ? PASSWORD);
    assert vm.environmentFiles == ["/var/lib/windows11/credentials.env"];
    assert vm.volumes == ["/var/lib/windows11/storage:/storage"];
    assert vm.ports == ["127.0.0.1:8006:8006/tcp" "127.0.0.1:3389:3389/tcp"];
    assert builtins.elem "--device=/dev/kvm" vm.extraOptions;
    assert builtins.elem "--device=/dev/net/tun" vm.extraOptions;
    assert builtins.elem "windows11-prepare.service" service.requires;
    assert service.serviceConfig.TimeoutStopSec > 120;
    assert config.virtualisation.docker.enable;
      pkgs.runCommand "rt-windows11-check" {} ''
        export STATE_DIRECTORY="$TMPDIR/windows11"
        mkdir -m 700 "$STATE_DIRECTORY"
        ${prepare}
        test "$(stat -c %a "$STATE_DIRECTORY/credentials.env")" = 600
        test "$(stat -c %a "$STATE_DIRECTORY/storage")" = 700
        grep -Eq '^PASSWORD=[0-9a-f]{48}$' "$STATE_DIRECTORY/credentials.env"
        cp "$STATE_DIRECTORY/credentials.env" "$TMPDIR/original.env"
        printf 'preserve guest data\n' > "$STATE_DIRECTORY/storage/guest-data"
        ${prepare}
        cmp "$STATE_DIRECTORY/credentials.env" "$TMPDIR/original.env"
        test -f "$STATE_DIRECTORY/storage/guest-data"
        # Missing installation credentials must fail closed, not rotate them.
        rm "$STATE_DIRECTORY/credentials.env"
        if ${prepare}; then
          echo 'Unexpectedly replaced credentials for an existing VM' >&2
          exit 1
        fi
        test ! -e "$STATE_DIRECTORY/credentials.env"
        test -f "$STATE_DIRECTORY/storage/guest-data"
        touch "$out"
      '';
  };
}
