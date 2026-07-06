# photosync

Sync photos from a digital camera or other external devices to a local computer while automatically organizing them and generating a static gallery website.

## Setup

Deployed as a NixOS system service via the `services-photosync` flake module (`nix/features/services/photosync.nix`). The module packages the `bin/` scripts with their runtime dependencies and runs `photosync-watch` as user `mantas`.

For the automatic mounting and copying to work. External device root partition needs to have `.photosync` file with contents of the identifier (can be any string, as long as it is unique across different devices/volumes).

State (per-device cache lists) lives in `~/.local/state/photosync`.

## Process

Main processes:

1. `photosync-watch` - the base process, watches for newly plugged in drives
2. `photosync-mount` - handles drive mounting and unmounting
3. `photosync-process` - mounts and checks drives that are intended to be processed
4. `photosync-cache` - caches file list
5. `photosync` - copies photos from one directory (ext. drive in this case) to a local folder

Helpers:

- `photosync-notify` - notifies about the process (Pushover)
- `photosync-gallery` - generates a static gallery website

## Dependencies

Provided by the nix package:

- `udisks2` - unprivileged device mounting
- `exiftool` - retrieving photo creation date
- `curl` - for notifications
- `docker` - for static gallery generation

## Gallery

For static gallery generation library [thumbsup](https://thumbsup.github.io) is used.
