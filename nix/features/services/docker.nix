{...}: {
  flake.modules.nixos."services-docker" = {
    pkgs,
    config,
    ...
  }: let
    dockerPrune = pkgs.writeShellApplication {
      name = "docker-prune";

      runtimeInputs = [
        config.virtualisation.docker.rootless.package
        pkgs.coreutils
        pkgs.findutils
      ];

      text =
        /*
        bash
        */
        ''
          # Containers are pruned by stop time, since `until` filters on creation time
          # and would remove long-lived containers stopped by a reboot
          cutoff="$(date -d '7 days ago' +%s)"

          docker ps -aq --filter status=exited --filter status=dead |
            xargs -r docker inspect --format '{{.Id}} {{.State.FinishedAt}}' |
            while read -r id finished; do
              if (($(date -d "$finished" +%s) < cutoff)); then
                docker rm "$id"
              fi
            done

          docker network prune -f --filter until=168h
          docker image prune -f --filter until=168h
          docker builder prune -f --filter until=168h
        '';
    };
  in {
    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
        daemon.settings = {
          ip6tables = false;
        };
      };
    };

    environment.sessionVariables = {
      DOCKER_CONFIG = "$HOME/.config/docker";
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
        ExecStart = "${dockerPrune}/bin/docker-prune";
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
