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
