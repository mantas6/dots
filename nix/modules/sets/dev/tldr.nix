{pkgs, ...}: {
  environment.systemPackages = [pkgs.tealdeer];

  systemd.user.services."tldr-update" = {
    script = "${pkgs.tealdeer}/bin/tldr -u";

    serviceConfig = {
      Type = "oneshot";
    };
  };

  systemd.user.timers."tldr-update" = {
    wantedBy = ["timers.target"];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      Unit = "tldr-update.service";
    };
  };
}
