{...}: {
  # For small VPS hosts (1 core, ~2 GB RAM) where the nightly autoUpgrade
  # starves the workload. nixos-upgrade runs as root without NIX_REMOTE, so
  # eval, substitution and builds all run inside its own cgroup: limits on the
  # unit are what matter, nix.daemon* knobs don't apply to it.
  flake.modules.nixos."quirks-low-resource" = {pkgs, ...}: {
    systemd.services.nixos-upgrade.serviceConfig = {
      Nice = 19;
      CPUSchedulingPolicy = "idle";
      CPUWeight = "idle";
      IOSchedulingClass = "idle";
      IOWeight = 10;
      # Soft cap: eval peaks at 0.8-1.2 GB, a hard MemoryMax would OOM it.
      MemoryHigh = "1G";
      OOMScoreAdjust = 500;
    };

    nix.settings = {
      max-substitution-jobs = 4;
      http-connections = 8;
    };

    # Spread the weekly gc/optimise, both default to Mon 00:00.
    nix.gc.randomizedDelaySec = "1h";
    nix.optimise.randomizedDelaySec = "1h";

    system.autoUpgrade.randomizedDelaySec = "15min";

    # The slowest locally built derivation, never substitutable for flake systems.
    documentation.nixos.enable = false;

    # Stable neovim avoids fetching and evaluating a second nixpkgs tree.
    features.neovim.package = pkgs.neovim;
  };
}
