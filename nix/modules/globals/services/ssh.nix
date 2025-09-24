{...}: {
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";

      PasswordAuthentication = false;

      ChallengeResponseAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
