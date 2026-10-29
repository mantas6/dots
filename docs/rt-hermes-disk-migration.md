# rt-hermes-disk-migration

Move Hermes state (`/var/lib/hermes`) on `rt` onto a dedicated NVMe drive.

Target layout (from `nix/hosts/rt/default.nix`):

- `disko.devices.disk.hermes`: `/dev/nvme0n1`, GPT, one partition `hermes`, ext4, mounted at `/hermes`
- fstab device: `/dev/disk/by-partlabel/disk-hermes-hermes`
- `/var/lib/hermes`: bind mount of `/hermes`
- both mounts are `neededForBoot` (mounted in the initrd), because the `hermes-agent` activation script writes into `/var/lib/hermes` before regular fstab mounts
- `hermes-agent.service`: `RequiresMountsFor=/var/lib/hermes`

Because the mounts are needed for boot, the drive must be partitioned and formatted (step 3) before the new config is deployed (step 5). Otherwise the next boot stops in the initrd emergency shell.

Run the commands on `rt` as root unless marked otherwise. Tools that may be missing:

```sh
nix shell nixpkgs#gptfdisk nixpkgs#parted nixpkgs#rsync nixpkgs#nvme-cli
```

## 1. Pre-checks

Install the drive, boot, then confirm that it shows up:

```sh
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,FSTYPE,MOUNTPOINTS
nvme list
ls -l /dev/disk/by-id/ | grep nvme
```

Confirm that it is empty. These commands should print nothing:

```sh
lsblk -n /dev/nvme0n1 -o NAME | tail -n +2   # no partitions
blkid /dev/nvme0n1                           # no signatures
wipefs -n /dev/nvme0n1                       # no signatures
```

The device name must match `disko.devices.disk.hermes.device`. If the drive enumerates differently, update the config before you continue. Only the format step uses the name. The fstab uses the partlabel.

Make sure that no other disk already has the partlabel. This command should print nothing:

```sh
ls -l /dev/disk/by-partlabel/ | grep disk-hermes-hermes
```

Check the Hermes units and note their state:

```sh
systemctl list-units '*hermes*'
systemctl status hermes-agent
du -sh /var/lib/hermes
ls -la /var/lib/hermes
```

## 2. Backup

```sh
systemctl stop hermes-agent
systemctl is-active hermes-agent   # inactive

mkdir -p /root/hermes-backup
stamp=$(date +%Y%m%d-%H%M%S)
tar --numeric-owner --acls --xattrs -czpf "/root/hermes-backup/hermes-$stamp.tar.gz" -C /var/lib/hermes .
```

Verify:

```sh
gzip -t "/root/hermes-backup/hermes-$stamp.tar.gz"
tar -tzf "/root/hermes-backup/hermes-$stamp.tar.gz" | wc -l
find /var/lib/hermes | wc -l   # should match (tar skips sockets)
tar -tzf "/root/hermes-backup/hermes-$stamp.tar.gz" | grep -E '^\./(env|auth\.json)$'
```

Leave `hermes-agent` stopped until step 5.

## 3. Format the new disk only

Do NOT run `disko --mode format` or `disko --mode destroy,format,mount` with `--flake .#rt`. The disko CLI has no option to select one disk. It runs the scripts for every disk in the config, and this includes `main-disk` (`/dev/sda`, the root disk). `--disk NAME DEVICE` exists only in `disko-install`, and it only changes the device path of a disk. It does not filter disks.

These manual commands are the same as the disko script for this disk. You can print that script from the repo on your workstation:

```sh
nix eval --raw .#nixosConfigurations.rt.config.disko.devices.disk.hermes._create
```

The script touches only `/dev/nvme0n1`. It runs `sgdisk --clear` on the disk, then `sgdisk --align-end --new=1:0:-0 ... --change-name=1:disk-hermes-hermes --typecode=1:8300`, then `mkfs.ext4 /dev/disk/by-partlabel/disk-hermes-hermes`. It sets no extra mkfs arguments.

On `rt`:

```sh
sgdisk --zap-all /dev/nvme0n1
sgdisk --clear /dev/nvme0n1
sgdisk --align-end --new=1:0:-0 --partition-guid=1:R \
  --change-name=1:disk-hermes-hermes --typecode=1:8300 --attributes=1:=:0 \
  /dev/nvme0n1
partprobe /dev/nvme0n1
udevadm trigger --subsystem-match=block
udevadm settle --timeout 120
```

Verify the partlabel, and then create the filesystem:

```sh
sgdisk -p /dev/nvme0n1
ls -l /dev/disk/by-partlabel/disk-hermes-hermes   # -> ../../nvme0n1p1
mkfs.ext4 /dev/disk/by-partlabel/disk-hermes-hermes
blkid /dev/disk/by-partlabel/disk-hermes-hermes   # TYPE="ext4" PARTLABEL="disk-hermes-hermes"
```

## 4. Copy data

```sh
mkdir -p /mnt/hermes
mount /dev/disk/by-partlabel/disk-hermes-hermes /mnt/hermes
rsync -aHAX --numeric-ids --info=progress2 /var/lib/hermes/ /mnt/hermes/
```

The trailing slash on the source also copies the owner and mode of the top directory (`hermes:hermes`, `2770`) to the new filesystem root.

Verify. The checksum dry run should list nothing:

```sh
rsync -aHAXc --numeric-ids --dry-run --itemize-changes --delete --exclude=/lost+found /var/lib/hermes/ /mnt/hermes/
find /var/lib/hermes | wc -l
find /mnt/hermes -path /mnt/hermes/lost+found -prune -o -print | wc -l
du -s --apparent-size /var/lib/hermes /mnt/hermes   # roughly equal
stat -c '%U:%G %a %n' /var/lib/hermes /mnt/hermes
ls -la /mnt/hermes/env /mnt/hermes/auth.json
```

Unmount:

```sh
umount /mnt/hermes
```

## 5. Deploy

Keep `hermes-agent` stopped. If the service holds `/var/lib/hermes`, the bind mount can fail to activate. Run this command from the repo on your workstation:

```sh
nixos-rebuild switch --flake .#rt --target-host rt --ask-sudo-password
```

What the switch does:

- `/hermes` is mounted from `/dev/disk/by-partlabel/disk-hermes-hermes`
- `/var/lib/hermes` becomes a bind mount of `/hermes`. The old directory on the root disk stays in place under the mount, and you cannot see it. It is your fallback.
- `hermes-agent` gets `RequiresMountsFor=/var/lib/hermes`, so it does not start without the mount.
- on this first switch the activation script still runs before the mount units start, so it writes `.env`, `config.yaml` and `auth.json` to the old copy. From the reboot below on, it runs with the NVMe mounted.
- a new initrd is built that mounts `/hermes` and `/var/lib/hermes` before stage 2 on every later boot.

Check the mounts. If they are missing, start them, and then start the service:

```sh
findmnt /hermes && findmnt /var/lib/hermes || systemctl start hermes.mount var-lib-hermes.mount
systemctl start hermes-agent
```

Reboot to confirm that everything comes up from the initrd:

```sh
reboot
```

## 6. Verify

```sh
findmnt /hermes            # SOURCE /dev/nvme0n1p1, FSTYPE ext4
findmnt /var/lib/hermes    # SOURCE /dev/nvme0n1p1, FSTYPE ext4

stat -c '%U:%G %a %n' /var/lib/hermes
ls -la /var/lib/hermes/env /var/lib/hermes/auth.json

systemctl status hermes-agent
systemctl show hermes-agent -p RequiresMountsFor
journalctl -u hermes-agent -b
```

Make sure that Hermes responds as before, and that its sessions and memories are still there.

## 7. Cleanup

Wait until the setup has run without problems for some days. Until then, you can keep the old copy as a fallback. To remove it, bind-mount `/` to a second location. This shows the root filesystem without the mounts on top of it:

```sh
mkdir -p /mnt/root
mount --bind / /mnt/root
ls -la /mnt/root/var/lib/hermes   # old copy, not the NVMe
findmnt /mnt/root/var/lib/hermes  # must print nothing
find /mnt/root/var/lib/hermes -mindepth 1 -delete   # or trash, if available
umount /mnt/root
```

Keep the directory itself, because it is the mount point. Keep `/root/hermes-backup/hermes-*.tar.gz` for a few weeks.

## 8. Rollback

On `rt`, stop the service and then switch to the previous generation:

```sh
systemctl stop hermes-agent
nixos-rebuild switch --rollback
umount /var/lib/hermes /hermes   # the switch does not unmount them
findmnt /var/lib/hermes          # should print nothing
```

You can also check out the previous commit in the repo and run the deploy command from step 5 again. If the system does not boot (for example because the drive is missing, so the initrd cannot mount `/hermes`), select the previous generation in the boot menu.

After a rollback, the service uses the old copy on the root disk again. That copy is only as current as the copy in step 4. To keep changes that were made after the migration, copy them back before you start the service:

```sh
mount /dev/disk/by-partlabel/disk-hermes-hermes /mnt/hermes
rsync -aHAX --numeric-ids --delete --exclude=/lost+found /mnt/hermes/ /var/lib/hermes/
umount /mnt/hermes
```

Then start the service:

```sh
systemctl start hermes-agent
```

If you already did the cleanup in step 7, restore the data from the NVMe as shown above. You can also restore it from the tarball:

```sh
tar --numeric-owner --acls --xattrs -xzpf /root/hermes-backup/hermes-<stamp>.tar.gz -C /var/lib/hermes
```
