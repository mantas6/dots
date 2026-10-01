{...}: {
  flake.modules.nixos.base = {...}: {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";

        PasswordAuthentication = false;

        ChallengeResponseAuthentication = false;
        KbdInteractiveAuthentication = false;

        # Only accounts that hold authorized keys; root stays for remote deploys.
        AllowUsers = ["mantas" "root"];
      };
    };
  };
}
