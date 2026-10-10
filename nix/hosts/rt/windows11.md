# Windows 11 on rt

`rt` runs a persistent Windows 11 Pro VM with **8 GiB RAM**, two virtual CPU
cores and a 64 GiB sparse qcow2 disk. QEMU/KVM is packaged by the
[dockur/windows](https://github.com/dockur/windows/tree/v6.05) unattended
installer, managed declaratively by NixOS OCI containers and systemd. The
installer image is pinned to the verified Docker Hub **6.05** manifest digest.

This is a real virtual machine, not a Windows container sharing the Linux
kernel. Only `rt` imports this configuration; no other host gains Docker or a VM.

## First installation

1. Enable Intel VT-x in `rt`'s firmware. The VM requires `/dev/kvm` and
   `/dev/net/tun`; there is no software-emulation fallback.
2. Provide at least 8 GiB of **available** RAM plus headroom for NixOS and the
   container/installer. Allow at least 80 GiB of free disk space for the 64 GiB
   guest disk, download and installation workspace. Sparse allocation is not a
   hard storage quota.
3. Apply the flake on `rt` using the usual deployment workflow, or from the repo:

   ```sh
   sudo nixos-rebuild switch --flake .#rt
   ```

The boot-enabled `docker-windows11.service` downloads Windows and installs it
without manual ISO mounting or setup clicks. This needs Internet access and can
take a while. Watch progress with:

```sh
sudo journalctl -fu docker-windows11.service
```

The Windows media selected by `VERSION=11` follows the installer's upstream
Windows 11 Pro download, rather than a byte-pinned Windows ISO. The container
image is reproducible, but Microsoft's downloaded media and Windows updates are
not. Rebuilding the host does **not** reinstall an existing guest or declaratively
manage software/settings inside it. A valid Windows license is still required;
this configuration does not activate Windows.

## Connect securely

Both the web console and RDP bind to loopback on `rt`. No firewall ports are
opened, no host directories are shared with Windows, and automatic guest login
is disabled. The browser console has no separate authentication, so retain these
loopback bindings.

From your client:

```sh
ssh -N -L 8006:127.0.0.1:8006 -L 13389:127.0.0.1:3389 mantas@rt
```

Then open `http://127.0.0.1:8006` to watch setup or use the desktop console.
After installation, connect an RDP client to `127.0.0.1:13389` as `mantas`.
RDP UDP is intentionally not published: the SSH tunnel carries TCP only.

A random password is generated once on `rt`, outside Git and the Nix store, in
`/var/lib/windows11/credentials.env` (root-only, mode `0600`). Retrieve it locally
on `rt`, or over your authenticated SSH connection:

```sh
sudo cat /var/lib/windows11/credentials.env
```

Do not post that value in chat or commit it. Treat it as the **installation**
password: changing this file after setup does not change the Windows account
password. If you change the password inside Windows, keep your password manager
up to date. Root/Docker administrators can inspect container environment values;
this file is not a substitute for isolation from host administrators.

## Lifecycle and backups

- Guest disk, firmware/TPM state and installer state persist under
  `/var/lib/windows11/storage`, owned by root. Do not delete it when rebuilding.
- NixOS manages start/restart at boot and configuration changes. Stop/restart
  manually with `sudo systemctl stop docker-windows11` or
  `sudo systemctl restart docker-windows11`.
- Shutdown permits 105 seconds for guest ACPI shutdown, 120 seconds in Docker,
  and 150 seconds for systemd. Do not force-kill during installation or updates.
- For a consistent backup, stop the VM, copy **all** of `/var/lib/windows11`
  (including credentials and firmware/TPM state), then start the VM again. Keep
  backups private. If BitLocker is enabled, also save its recovery key separately.
- Existing storage without installation credentials fails closed: restore the
  credentials file from backup instead of silently generating a new password.
- Removing the Nix configuration stops management but does not delete data.
  There is no automatic reset or destructive reinstall operation.

## Validation

```sh
nix flake check
nix build .#checks.x86_64-linux.rt-windows11
```

The check asserts the host VM configuration and executes credential preparation
in a disposable directory: restrictive permissions, first-run generation,
restart idempotence, guest-data preservation, and failure on missing credentials.
It does not download or boot Windows. Confirm actual installation and RDP access
on `rt` after deployment.
