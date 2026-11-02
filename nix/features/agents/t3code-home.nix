{...}: {
  # Nix-managed $HOME for hosts that only run T3 Code and the agents it launches.
  # Replaces the stowed ~/.dots checkout with a handful of files taken from this repo.
  flake.modules.nixos."agents-t3code-home" = {
    lib,
    pkgs,
    config,
    ...
  }: let
    user = "mantas";
    inherit (config.users.users.${user}) group;
    home = ../../../home;

    # Read-only symlinks into the nix store
    linked = [
      ".claude/CLAUDE.md"
      ".config/opencode/AGENTS.md"
      ".codex/AGENTS.md"
      ".config/git/config"
      ".config/git/ignore"
      ".config/composer/composer.json"
      ".config/composer/composer.lock"
      ".ignore"
    ];

    # Writable copies for files the tool itself rewrites, reset to the repo version on every switch and boot
    copied = [
      ".claude/settings.json"
    ];

    managed = linked ++ copied;

    # Only the selected files, so unrelated repo changes don't produce a new store path
    files = lib.fileset.toSource {
      root = home;
      fileset = lib.fileset.unions (map (p: home + "/${p}") managed);
    };

    # Every ancestor directory of a managed path (".config", ".config/git", ...)
    parents = lib.unique (lib.concatMap (
        p: let
          parts = lib.init (lib.splitString "/" p);
        in
          lib.genList (i: lib.concatStringsSep "/" (lib.take (i + 1) parts)) (lib.length parts)
      )
      managed);
  in {
    # No zsh config from sh/ on this host; the t3code service sets the environment it needs
    users.users.${user}.shell = pkgs.bashInteractive;

    systemd.user.tmpfiles.users.${user}.rules =
      map (p: "L+ %h/${p} - - - - ${files}/${p}") linked
      # C needs an explicit owner: with "-" it tries to keep the store's root ownership and fails
      ++ lib.concatMap (p: [
        "r %h/${p}"
        "C %h/${p} 0644 ${user} ${group} - ${files}/${p}"
      ])
      copied;

    # Stow folds whole directories into symlinks (e.g. ~/.config/git -> ../.dots/home/.config/git) and
    # tmpfiles would follow them and write into the checkout. Replace such symlinks with real directories.
    # Activation snippets run in name order, so this one must sort before the upstream "tmpfiles" snippet.
    system.userActivationScripts.t3code-home-unfold = ''
      if [[ "$(id -un)" == ${user} ]]; then
        for dir in ${lib.escapeShellArgs parents}; do
          [[ -L "$HOME/$dir" ]] && rm -v "$HOME/$dir"
        done
      fi
    '';
  };
}
