# photosync

Sync photos from a digital camera or other external devices to a local computer while automatically organizing them and generating a static gallery website.

## Setup

Run the `./install` script. This will create and enable user `systemd` service.

Run `./bin/photosync-env photosync-watch` to start manually.

For the automatic mounting and copying to work. External device root partition needs to have `.photosync` file with contents of the identifier (can be any string, as long as it is unique across different devices/volumes).

## Process

Main processes:

1. `photosync-env` - sets up environment and launches all processes
2. `photosync-watch` - the base process, watches for newly plugged in drives
3. `photosync-mount` - handles drive mounting and unmounting
4. `photosync-process` - mounts and checks drives that are intended to be processed
5. `photosync-cache` - caches file list
6. `photosync` - copies photos from one directory (ext. drive in this case) to a local folder

Helpers:

- `photosync-serve` - serves the gallery
- `photosync-notify` - notifies about the process (Pushover)
- `photosync-gallery` - generates a static gallery website

## Dependencies

- `udisks2` - unprivileged device mounting
- `exiftool` - retrieving photo creation date
- `curl` - for notifications
- `docker` - for static gallery generation

## Gallery

For static gallery generation library [thumbsup](https://thumbsup.github.io) is used.
