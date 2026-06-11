{inputs, ...}: {
  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  config = {
    services.hermes-agent = {
      enable = true;
      settings.model.default = "openai/chatgpt-5.5";
      environmentFiles = ["/var/lib/hermes/env"];

      authFile = "/var/lib/hermes/auth.json";
      authFileForceOverwrite = true; # overwrite on every activation

      addToSystemPackages = true;
    };

    disko.devices.disk.main-disk.device = "/dev/sda";

    features.sets = [
      "disks.normal"
      "jobs.updates"
      "progs.shell"
      "purposes.app-server"
      "services.docker"
    ];

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
