{...}: {
  flake.modules.nixos."purposes-app-server" = {
    self,
    config,
    pkgs,
    ...
  }: let
    userName = "mantas";

    # Shared by the PHP CLI and the PHP embedded in frankenphp.
    phpIniExtra = ''
      memory_limit = 128M
      expose_php = Off
      display_errors = Off
      log_errors = On

      realpath_cache_size = 4096K
      realpath_cache_ttl = 600
    '';
    # - opcache.enable=1, opcache.memory_consumption=256, opcache.max_accelerated_files=20000
    # - upload_max_filesize / post_max_size (defaults are 2M)
    # - memory_limit (default 128M may be tight)

    phpConfigured = pkgs.php85.buildEnv {
      # pdo, pdo_sqlite, mbstring, bcmath, curl, zip, intl, pcntl, posix are
      # already part of the default extension set.
      extensions = {
        enabled,
        all,
      }:
        enabled
        ++ (with all; [
          redis
        ]);

      extraConfig = phpIniExtra;
    };

    # Upstream's prebuilt release (embedded PHP 8.5 with its own extensions),
    # patched for NixOS; see nix/packages/frankenphp-bin.nix. Octane looks on
    # PATH before base_path, so it never downloads its own unpatched binary.
    frankenphp = self.packages.${pkgs.stdenv.hostPlatform.system}.frankenphp-bin.override {
      phpExtraConfig = phpIniExtra;
    };

    phpEnv = with pkgs; [
      phpConfigured
      phpConfigured.packages.composer
    ];

    # Tools the app shells out to, beyond systemd's default service PATH.
    serviceTools = with pkgs; [
      gzip
      sqlite
    ];

    appRoot = "/home/${userName}/Sat";

    defaultServiceConfig = {
      User = userName;
      WorkingDirectory = "${appRoot}/current";
      Restart = "always";
      RestartSec = 2;

      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectSystem = "strict";
      # The app lives in $HOME; releases are read-only, writes go to the
      # shared storage dir and the current release's bootstrap cache.
      ProtectHome = "read-only";
      ReadWritePaths = [
        "${appRoot}/storage"
        "${appRoot}/current/bootstrap/cache"
      ];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
      RestrictSUIDSGID = true;
      LockPersonality = true;
      UMask = "0027";

      LimitNOFILE = 65536;
      TasksMax = 4096;

      # Shared writable state outside the app, at /var/lib/sat.
      StateDirectory = "sat";
    };

    defaultServiceOptions = {
      enable = true;

      path = phpEnv ++ serviceTools;

      serviceConfig = defaultServiceConfig;

      wantedBy = ["multi-user.target"];
      after = ["network-online.target" "redis-main.service"];
      wants = ["network-online.target" "redis-main.service"];
      startLimitIntervalSec = 0;
    };

    artisan = pkgs.writeShellScript "artisan" ''
      exec php artisan "$@"
    '';
  in {
    age.secrets.sat-caddy-env.file = ./../../_lib/secrets/sat-caddy-env.age;

    environment.systemPackages =
      phpEnv
      ++ serviceTools
      ++ [
        pkgs.git
      ];

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [80 443];
      allowedUDPPorts = [443];
    };

    services.caddy = {
      enable = true;
      # KEY=value env file holding APP_DOMAIN and APP_DOMAIN_AUX.
      environmentFile = config.age.secrets.sat-caddy-env.path;

      # Serve the main certificate to TLS clients that send no SNI. The NodeMCU
      # release firmware never sets a TLS hostname, and without this Caddy
      # aborts the handshake (alert 80) before any HTTP is exchanged.
      globalConfig = ''
        default_sni {$APP_DOMAIN}
      '';

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
        hostName = "{$APP_DOMAIN} {$APP_DOMAIN_AUX:}";
        extraConfig = ''
          encode zstd gzip
          # Deploys run `octane:stop` and systemd restarts sat-octane; hold and
          # retry requests while the upstream is down instead of returning 502.
          reverse_proxy 127.0.0.1:8000 {
            lb_try_duration 30s
            lb_try_interval 250ms
          }
        '';
      };
    };

    services.redis.servers.main = {
      enable = true;
      port = 6379;
      appendOnly = true;
    };

    systemd.services.sat-schedule =
      defaultServiceOptions
      // {
        # Backgrounded so the unit finishes at once and the next tick can start
        # a new run even if this one is still going; KillMode=process keeps
        # the run alive after the unit stops.
        script = "timeout 1h php artisan schedule:run --no-interaction &";

        serviceConfig =
          defaultServiceConfig
          // {
            Type = "oneshot";
            Restart = "no";
            KillMode = "process";
          };

        restartIfChanged = false;
        unitConfig.X-StopOnRemoval = false;

        startAt = "minutely";
      };

    systemd.services.sat-octane =
      defaultServiceOptions
      // {
        # The admin port is moved off 2019, which the system Caddy already uses.
        # The php CLI's wrapper exports PHP_INI_SCAN_DIR, which the spawned
        # frankenphp inherits; its own wrapper pins its ini dir so that doesn't leak in.
        path = [phpConfigured frankenphp] ++ serviceTools;

        script = "php artisan octane:start --server=frankenphp --host=127.0.0.1 --port=8000 --admin-port=2020 --workers=8 --max-requests=500";

        # FrankenPHP's embedded Caddy keeps its config and data outside the read-only home.
        environment = {
          XDG_CONFIG_HOME = "/var/lib/sat";
          XDG_DATA_HOME = "/var/lib/sat";
        };

        serviceConfig =
          defaultServiceConfig
          // {
            # Workers keep the release path resolved at start; deploys switching `current` need a restart.
            ExecReload = "${artisan} octane:reload";
            TimeoutStopSec = "30s";
            # Deploys run `octane:stop`; come back quickly so Caddy's retries bridge the gap.
            RestartSec = "500ms";
          };
      };

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

    # The app's workers push telemetry to this agent over 127.0.0.1:2407; the
    # token comes from the app's env. Workers don't depend on it, since the
    # client drops data quietly while the agent is down.
    systemd.services.sat-nightwatch =
      defaultServiceOptions
      // {
        script = "php artisan nightwatch:agent";
      };
  };
}
