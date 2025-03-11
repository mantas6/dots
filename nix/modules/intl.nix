{pkgs, ...}: {
  time.timeZone = "Europe/Vilnius";
  time.hardwareClockInLocalTime = true;

  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    packages = with pkgs; [terminus_font];
    font = "ter-v32n";
    keyMap = "us";
  };
}
