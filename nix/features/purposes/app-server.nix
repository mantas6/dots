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
      # - opcache.enable=1, opcache.memory_consumption=256, opcache.max_accelerated_files=20000
      # - upload_max_filesize / post_max_size (defaults are 2M)
      # - memory_limit (default 128M may be tight)
      # - expose_php = Off
      # - realpath_cache_size = 4096K / realpath_cache_ttl = 600
    };

    phpEnv = with pkgs; [
      phpConfigured
      phpConfigured.packages.composer
      sqlite
    ];

    # The services have no sandboxing or resource limits:
    #
    # - PrivateTmp = true, ProtectSystem = "strict", ProtectHome = "read-only" - basic hardening
    # - MemoryMax / CPUQuota - prevent runaway processes
    # - ReadWritePaths to limit filesystem writes to what's needed

    defaultServiceConfig = {
      User = userName;
      WorkingDirectory = "/home/${userName}/Sat/current";
      Restart = "always";
      RestartSec = 1;

      NoNewPrivileges = true;
      PrivateTmp = true;
    };

    defaultServiceOptions = {
      enable = true;

      path = phpEnv;

      serviceConfig = defaultServiceConfig;

      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
    };
  in {
    age.secrets.sat-caddy-env.file = ./../../_lib/secrets/sat-caddy-env.age;

    environment.systemPackages =
      phpEnv
      ++ [
        pkgs.git
      ];

    networking.firewall = {
      # enable = true;
      allowedTCPPorts = [80 443];
      allowedUDPPorts = [443];
    };

    services.caddy = {
      enable = true;
      # KEY=value env file holding APP_DOMAIN, APP_DOMAIN_AUX and ACME_EMAIL.
      environmentFile = config.age.secrets.sat-caddy-env.path;
      email = "{$ACME_EMAIL}";

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
        # Trailing ":" gives the placeholder an empty default so a missing
        # APP_DOMAIN_AUX does not break the site address.
        hostName = "{$APP_DOMAIN} {$APP_DOMAIN_AUX:}";
        extraConfig = ''
          encode zstd gzip

          header {
            -Server
            Strict-Transport-Security "max-age=31536000; includeSubDomains"
            X-Content-Type-Options nosniff
            Referrer-Policy strict-origin-when-cross-origin
          }

          request_body {
            max_size 25MB
          }

          reverse_proxy 127.0.0.1:8000 {
            # Keep retrying briefly while Octane workers reload on deploy.
            lb_try_duration 5s
          }
        '';
      };
    };

    services.redis.servers.main = {
      enable = true;
      # Horizon queues live here; RDB snapshots alone can lose recent jobs.
      appendOnly = true;
    };

    # - sat-schedule: redirects all output to /dev/null - you'll never see scheduler errors. At minimum send stderr somewhere useful.
    systemd.services.sat-schedule =
      defaultServiceOptions
      // {
        script = "php artisan schedule:run >> /dev/null 2>&1";

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

    # - sat-octane: no ExecReload for graceful worker restart (useful for deploys). Octane supports --max-requests to prevent memory leaks - not set here.
    systemd.services.sat-octane =
      defaultServiceOptions
      // {
        script = "php artisan octane:start --workers=8";
      };

    # - sat-horizon: the 3600s stop timeout is good, but there's no ExecStop = php artisan horizon:terminate for graceful shutdown signaling.
    systemd.services.sat-horizon =
      defaultServiceOptions
      // {
        script = "php artisan horizon";

        serviceConfig =
          defaultServiceConfig
          // {
            TimeoutStopSec = "3600s";
          };
      };
  };
}
