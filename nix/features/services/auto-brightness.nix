{...}: {
  flake.nixosModules."services-auto-brightness" = {...}: let
    # Same behaviour on AC and battery.
    timeouts = [60 60 60]; # capture every 60s (day/night/event)
    # ambient(0..1) -> backlight(0..1): linear 5%..40%.
    # clight fits a degree-2 polynomial, so >=3 (collinear) points are required;
    # the midpoint 0.225 keeps it a straight line.
    curve = [0.05 0.225 0.40];
  in {
    services.clight = {
      enable = true;
      settings = {
        backlight = {
          ac_timeouts = timeouts;
          batt_timeouts = timeouts;
          trans_fixed = 1000; # smooth 1s ramp per change
        };
        sensor = {
          ac_regression_points = curve;
          batt_regression_points = curve;
          # Lock webcam exposure so ambient light is measurable. Calibrate on-device:
          # 10094849 = EXPOSURE_AUTO (1 = manual), 10094850 = EXPOSURE_ABSOLUTE.
          settings = "10094849=1,10094850=166";
        };
        # Kiosk: ambient backlight only; disable everything else.
        gamma.disabled = true;
        dimmer.disabled = true;
        dpms.disabled = true;
        screen.disabled = true;
        keyboard.disabled = true;
      };
    };

    location = {
      provider = "manual";
      latitude = 54.0;
      longitude = 24.0;
    };

    # `mt` uses bare startx, which never reaches graphical-session.target (what the
    # upstream clight user unit binds to). Also start it from the user default.target,
    # reached on tty1 autologin. BACKLIGHT is screen-server agnostic (no DISPLAY needed).
    systemd.user.services.clight.wantedBy = ["default.target"];
  };
}
