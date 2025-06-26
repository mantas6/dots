{
  pkgs,
  lib,
  ...
}: {
  time.timeZone = "Europe/Vilnius";
  time.hardwareClockInLocalTime = true;

  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    packages = with pkgs; [terminus_font];
    # ls -1 /etc/kbd/consolefonts | sort | less
    font = lib.mkDefault "ter-v32n";
    keyMap = "us";
  };
}
