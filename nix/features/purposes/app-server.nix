{...}: {
  flake.modules.nixos."purposes-app-server" = {
    config,
    pkgs,
    ...
  }: let
    userName = "mantas";

    phpConfigured = pkgs.php85.buildEnv {
      extensions = {
        enabled,
        all,
      }:
        enabled
        ++ (with all; [
          pdo
          # pdo_mysql
          pdo_sqlite
          mbstring
          # xml
          bcmath
          curl
          zip
          intl
        ]);

      extraConfig = ''
        memory_limit = 128M
      '';
    };

    phpEnv = with pkgs; [
      phpConfigured
      phpConfigured.packages.composer
      sqlite
    ];

    defaultServiceConfig = {
      User = userName;
      WorkingDirectory = "/home/${userName}/Sat/current";
      Restart = "always";
      RestartSec = 2;

      NoNewPrivileges = true;
      PrivateTmp = true;
    };

    defaultServiceOptions = {
      enable = true;

      path = phpEnv;

      serviceConfig = defaultServiceConfig;

      wantedBy = ["multi-user.target"];
      after = ["network-online.target" "redis-main.service"];
      wants = ["network-online.target"];
      requires = ["redis-main.service"];
      startLimitIntervalSec = 0;
    };

    artisan = pkgs.writeShellScript "artisan" ''
      exec php artisan "$@"
    '';
  in {
    age.secrets.sat-caddy-env.file = ./../../_lib/secrets/sat-caddy-env.age;

    environment.systemPackages =
      phpEnv
      ++ [
        pkgs.git
      ];

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [80 443];
    };

    services.caddy = {
      enable = true;
      # KEY=value env file holding APP_DOMAIN and APP_DOMAIN_AUX.
      environmentFile = config.age.secrets.sat-caddy-env.path;

      # https://caddyserver.com/docs/caddyfile/patterns
      # {
      #     frankenphp
      #     order php_server before file_server
      # }
      #
      # example.com {
      # 	root /srv/public
      #     encode zstd br gzip
      #     php_server
      # }
      virtualHosts.app = {
        hostName = "{$APP_DOMAIN} {$APP_DOMAIN_AUX}";
        extraConfig = ''
          encode zstd gzip
          reverse_proxy 127.0.0.1:8000
        '';
      };
    };

    services.redis.servers.main = {
      enable = true;
      port = 6379;
    };

    systemd.services.sat-schedule =
      defaultServiceOptions
      // {
        script = "php artisan schedule:run --no-interaction";

        serviceConfig =
          defaultServiceConfig
          // {
            Type = "oneshot";
            Restart = "no";
          };

        restartIfChanged = false;
        unitConfig.X-StopOnRemoval = false;

        startAt = "minutely";
      };

    systemd.services.sat-octane =
      defaultServiceOptions
      // {
        script = "php artisan octane:start --server=roadrunner --host=127.0.0.1 --port=8000 --workers=auto --max-requests=500";

        serviceConfig =
          defaultServiceConfig
          // {
            ExecReload = "${artisan} octane:reload";
            ExecStop = "${artisan} octane:stop";
            TimeoutStopSec = "30s";
          };
      };

    systemd.services.sat-horizon =
      defaultServiceOptions
      // {
        script = "php artisan horizon";

        serviceConfig =
          defaultServiceConfig
          // {
            ExecStop = "${artisan} horizon:terminate --wait";
            KillSignal = "SIGTERM";
            TimeoutStopSec = "3600s";
          };
      };
  };
}
