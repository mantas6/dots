{
  pkgs,
  lib,
  config,
  ...
}: let
  name = "purposes.app-server";

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
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      environment.systemPackages = phpEnv;

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [22 80 443];
      };

      services.caddy = {
        enable = true;
        # Runtime-only hostname secret, e.g. APP_DOMAIN=example.com
        environmentFile = "/var/lib/secrets/caddy.env";

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
        extraConfig = ''
          encode zstd gzip

          {$APP_DOMAIN} {
            reverse_proxy localhost:8000
          }
        '';
      };

      services.redis.servers.main = {
        enable = true;
        port = 6379;
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
    })
  ];
}
