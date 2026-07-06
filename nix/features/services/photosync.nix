{...}: {
  flake.nixosModules."services-photosync" = {
    self,
    pkgs,
    ...
  }: let
    HOME = "/home/mantas";
    PHOTOSYNC_CACHE = "${HOME}/.local/state/photosync";
    PHOTOSYNC_ORIGINALS = "${HOME}/Pictures/Gallery/Originals";
    PHOTOSYNC_SITE = "${HOME}/Pictures/Gallery/Site";

    photosyncPkg = self.packages.${pkgs.stdenv.hostPlatform.system}.photosync;
  in {
    systemd.services.photosync = {
      description = "Photosync — auto-import photos from external devices";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      environment = {
        inherit PHOTOSYNC_CACHE PHOTOSYNC_ORIGINALS PHOTOSYNC_SITE;
      };

      serviceConfig = {
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${PHOTOSYNC_CACHE} ${PHOTOSYNC_ORIGINALS} ${PHOTOSYNC_SITE}";
        ExecStart = "${photosyncPkg}/bin/photosync-watch";
        User = "mantas";
        Restart = "always";
        RestartSec = "10s";
        Type = "simple";
        SupplementaryGroups = ["docker"];
      };
    };

    services.udisks2.enable = true;

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.user == "mantas" &&
            action.id.indexOf("org.freedesktop.udisks2.") == 0) {
          return polkit.Result.YES;
        }
      });
    '';

    services.caddy = {
      enable = true;
      user = "mantas";

      globalConfig = ''
        auto_https off
      '';

      virtualHosts = {
        "http://:8079" = {
          extraConfig = ''
            root * ${PHOTOSYNC_SITE}
            file_server
          '';
        };

        "http://:8080" = {
          extraConfig = ''
            root * ${PHOTOSYNC_ORIGINALS}
            file_server
          '';
        };

        "http://gal" = {
          extraConfig = ''
            reverse_proxy http://localhost:8079
          '';
        };
      };
    };

    environment.systemPackages = [photosyncPkg];
  };

  perSystem = {
    config,
    pkgs,
    ...
  }: {
    packages.sat-notify = pkgs.writeShellApplication {
      name = "sat-notify";
      runtimeInputs = [pkgs.curl pkgs.coreutils];
      text = ''
        message="$1"
        expire='+2 days'

        state_home=''${XDG_STATE_HOME:-"$HOME/.local/state"}
        state=''${SAT_JOURNAL_STATE:-"$state_home/sat"}

        if [ ! -f "$state/url" ]; then
          echo 'Error: URL is not configured. Use sat-login command to enter it.' >&2
          exit 1
        fi

        if [ ! -f "$state/token" ]; then
          echo 'Error: Token is not configured' >&2
          exit 1
        fi

        url=$(<"$state/url")
        token=$(<"$state/token")

        curl -fsSLX POST \
          -d "message=$message" \
          -d "expire=$expire" \
          -H "Authorization: Bearer $token" \
          "$url/api/notify"

        exit 0
      '';
    };

    packages.photosync = pkgs.stdenv.mkDerivation {
      pname = "photosync";
      version = "0.1.0";
      src = ../../../opt/photosync/.;

      nativeBuildInputs = [pkgs.makeWrapper];

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/bin"
        install -Dm755 bin/* "$out/bin/"

        for prog in "$out"/bin/*; do
          wrapProgram "$prog" --prefix PATH : ${
          pkgs.lib.makeBinPath [
            config.packages.sat-notify
            pkgs.udev
            pkgs.udisks2
            pkgs.util-linux
            pkgs.exiftool
            pkgs.coreutils
            pkgs.diffutils
            pkgs.findutils
            pkgs.gawk
            pkgs.gnused
            pkgs.gnugrep
            pkgs.docker
            pkgs.bash
          ]
        }:"$out/bin"
        done

        runHook postInstall
      '';
    };
  };
}
