{...}: {
  flake.nixosModules."services-docker" = {
    lib,
    config,
    ...
  }: {
    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };

    boot.kernel.sysctl = {
      "net.ipv4.ip_unprivileged_port_start" = 0;
    };

    systemd.user.services.docker-prune = {
      description = "Prune rootless docker resources";
      after = ["docker.service"];
      requires = ["docker.service"];
      unitConfig.ConditionUser = "!root";
      serviceConfig = {
        Type = "oneshot";
        Environment = "DOCKER_HOST=unix://%t/docker.sock";
        ExecStart = "${lib.getExe config.virtualisation.docker.rootless.package} system prune -f";
      };
    };

    systemd.user.timers.docker-prune = {
      description = "Prune rootless docker resources";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };
  };
}
