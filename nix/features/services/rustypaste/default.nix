# Anonymous file drop for agents and browsers, served as http://pb on the LAN.
# `curl -F file=@x http://pb` prints the URL; files are deleted after 24h.
{...}: {
  flake.modules.nixos."services-rustypaste" = {pkgs, ...}: let
    port = 8090;
    maxSize = "512MB";
    url = "http://pb";

    settings = (pkgs.formats.toml {}).generate "rustypaste.toml" {
      config.refresh_rate = "1s";

      server = {
        address = "127.0.0.1:${toString port}";
        inherit url;
        max_content_length = maxSize;
        upload_path = "/var/lib/rustypaste";
        timeout = "120s";
        expose_version = false;
        # Nobody can enumerate what others uploaded
        expose_list = false;
        handle_spaces = "replace";
        # Served files get `nosniff` and a sandboxing CSP, so an uploaded
        # HTML/SVG cannot run scripts against the upload page's origin
        hardening = true;
      };

      landing_page = {
        file = "${./landing.html}";
        content_type = "text/html; charset=utf-8";
      };

      paste = {
        random_url = {
          type = "alphanumeric";
          length = 10;
        };
        default_extension = "txt";
        mime_override = [
          {
            mime = "text/plain";
            regex = "^.*\\.(log|txt|diff|sh|rs|toml|md)$";
          }
        ];
        text_mime_overrides = ["application/toml" "application/yaml" "application/x-yaml" "application/json"];
        duplicate_files = true;
        # Uploads can override with `-H 'expire: 1h'`
        default_expiry = "24h";
        delete_expired_files = {
          enabled = true;
          interval = "10min";
        };
      };
    };
  in {
    systemd.services.rustypaste = {
      description = "Rustypaste file drop";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      environment.CONFIG = "${settings}";
      serviceConfig = {
        ExecStart = "${pkgs.rustypaste}/bin/rustypaste";
        Restart = "always";
        RestartSec = 2;

        DynamicUser = true;
        StateDirectory = "rustypaste";
        WorkingDirectory = "/var/lib/rustypaste";

        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
        RestrictSUIDSGID = true;
        LockPersonality = true;
        UMask = "0077";
      };
    };

    services.caddy = {
      enable = true;
      virtualHosts."${url}".extraConfig = ''
        request_body {
          max_size ${maxSize}
        }
        reverse_proxy 127.0.0.1:${toString port}
      '';
    };
  };
}
