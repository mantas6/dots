{...}: {
  flake.modules.nixos."collections-desktop" = {
    lib,
    pkgs,
    ...
  }: let
    user = "mantas";
    credName = "keyring-login";
    credFile = "/var/lib/keyring-unlock/${user}.cred";
    daemon = "/run/wrappers/bin/gnome-keyring-daemon";

    unlock = pkgs.writeShellScript "gnome-keyring-unlock" ''
      # gnome-keyring only auto-unlocks (or creates) the keyring named "login";
      # make it the default so apps store their secrets there
      dir="$HOME/.local/share/keyrings"
      mkdir -p "$dir"
      printf login >"$dir/default"
      exec ${daemon} --replace --foreground --unlock --components=secrets \
        <"$CREDENTIALS_DIRECTORY/${credName}"
    '';

    check = pkgs.writeShellScript "gnome-keyring-check" ''
      ${pkgs.systemd}/bin/busctl --user get-property org.freedesktop.secrets \
        /org/freedesktop/secrets/collection/login \
        org.freedesktop.Secret.Collection Locked | grep -qx 'b false'
    '';
  in {
    # org.freedesktop.secrets provider for Electron safeStorage (T3 Code etc.)
    services.gnome.gnome-keyring.enable = true;
    # Defaults to on with gnome-keyring; conflicts with programs.ssh.startAgent
    services.gnome.gcr-ssh-agent.enable = false;
    # Desktops autologin, so PAM never has a password to hand to gnome-keyring
    security.pam.services.login.enableGnomeKeyring = lib.mkForce false;

    # Once per host: generate a random login keyring password and seal it to
    # this machine's TPM2 as a user-scoped systemd credential. Decrypting it
    # needs this TPM, so a copied disk or home backup can't unlock the keyring.
    systemd.services.keyring-unlock-seal = {
      description = "Seal a random gnome-keyring password to the TPM2";
      wantedBy = ["multi-user.target"];
      after = ["systemd-tpm2-setup.service"];

      unitConfig = {
        ConditionSecurity = "tpm2";
        ConditionPathExists = "!${credFile}";
      };

      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "keyring-unlock";
        UMask = "0077";
      };

      script = ''
        head -c 32 /dev/urandom | base64 -w0 |
          systemd-creds encrypt --user --uid=${user} --with-key=tpm2 \
            --name=${credName} - ${credFile}
        chown ${user} ${credFile}
      '';
    };

    # Runs gnome-keyring with the sealed password, so the login keyring is
    # unlocked (created on first run) before any app touches it. Started from
    # xinitrc; skipped on hosts without a sealed credential.
    systemd.user.services.gnome-keyring-unlock = {
      description = "gnome-keyring with TPM2-sealed login keyring unlock";

      unitConfig = {
        ConditionUser = user;
        ConditionPathExists = credFile;
      };

      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.secrets";
        LoadCredentialEncrypted = "${credName}:${credFile}";
        ExecStart = unlock;
        ExecStartPost = check;
      };
    };
  };
}
