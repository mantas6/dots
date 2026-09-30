{...}: {
  flake.modules.nixos."users-work" = let
    users = import ../../_lib/users.nix;
  in {
    # Unprivileged user for isolated day-to-day work (no wheel, no docker group).
    # No password by default: enter via SSH keys or `machinectl shell work@` from
    # mantas (`sudo -iu work` gives no systemd user session). Set
    # `users.users.work.hashedPassword` per host (mkpasswd) if needed.
    # Never forward the SSH agent into this user: the same keys unlock root.
    users.users.work = {
      isNormalUser = true;
      linger = true;
      openssh.authorizedKeys.keys = builtins.attrValues users.primary ++ builtins.attrValues users.others;
    };
  };
}
