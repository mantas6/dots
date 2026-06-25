{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.rt = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules."host-rt"];
  };

  flake.nixosModules."host-rt" = {pkgs-unstable, ...}: {
    imports =
      (with self.nixosModules; [
        base
        disks-normal
        jobs-updates
        progs-shell
        # purposes-app-server
        # services-docker
      ])
      ++ [
        inputs.hermes-agent.nixosModules.default
      ];

    services.hermes-agent = {
      enable = true;
      environmentFiles = ["/var/lib/hermes/env"];

      authFile = "/var/lib/hermes/auth.json";
      # authFileForceOverwrite = true; # overwrite on every activation

      addToSystemPackages = true;

      extraDependencyGroups = ["messaging" "voice"];

      settings = {
        model.default = "openai/gpt-5.5";
        stt.enabled = false;
        approvals = {
          mode = "smart";
        };
      };

      extraPackages = with pkgs-unstable; [
        # python313
        # python313Packages.pip

        curl
        wget
        jq
        file
        which
        tree
        unzip
        zip
        ripgrep
        fd
        uv

        imagemagick
        exiftool
        ffmpeg
        imagemagick

        sox
        espeak-ng
        yt-dlp
        caddy
        gh

        chromium
        nodejs_24
      ];
    };

    disko.devices.disk.main-disk.device = "/dev/sda";

    # boot.kernelParams = [
    #   "console=ttyS0,115200n8"
    #   "console=ttyS1,115200n8"
    #   "console=ttyS2,115200n8"
    #   "console=ttyS3,115200n8"
    # ];
    # boot.loader.grub.extraConfig = "
    #  serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
    #  terminal_input serial
    #  terminal_output serial
    #   ";

    networking.hostName = "rt";

    system.stateVersion = "25.05";
  };
}
