{...}: {
  flake.modules.nixos."host-l4" = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      exiftool
    ];

    services.udisks2.enable = true;

    services.caddy.virtualHosts."http://gal".extraConfig = ''
      reverse_proxy http://localhost:8079
    '';

    systemd.services.gallery = {
      description = "Gallery";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      path = [pkgs.caddy];
      script = ''
        caddy run --config - --adapter caddyfile <<'EOF'
          {
            admin off
          }

          # :8077 {
          #   root    * /home/mantas/Pictures/Nostalgia/Site
          #   file_server
          # }
          #
          # :8078 {
          #   root    * /home/mantas/Pictures/Nostalgia/Originals
          #   file_server
          # }

          :8079 {
            root    * /home/mantas/Pictures/Gallery/Site
            file_server
          }

          :8080 {
            root    * /home/mantas/Pictures/Gallery/Originals
            file_server
          }
        EOF
      '';
      serviceConfig = {
        User = "mantas";
        Restart = "always";
        Type = "simple";
      };
      environment = {
      };
    };
  };
}
