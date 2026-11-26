{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.lm = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-lm"];
  };

  flake.modules.nixos."host-lm" = {...}: {
    imports =
      (with self.modules.nixos; [
        base
        base-home
        disks-normal
        hardware-nvidia-headless
        containers-chatterbox
        jobs-os-upgrade-desktop
        services-ollama
        services-tailscale
        services-voicedm
      ])
      ++ [./_hardware.nix];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    features.wakeOnLanAdapterMAC = "10:ff:e0:6d:48:60";

    networking.hostName = "lm";

    # The local Ollama first, then the one on `au`; the model picker offers both
    services.voicedm.ollamaUrls = [
      "http://localhost:11434"
      "http://au:11434"
    ];

    system.stateVersion = "26.05";
  };
}
