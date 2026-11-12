{...}: {
  flake.modules.nixos."progs-shell" = {
    lib,
    config,
    pkgs,
    pkgs-unstable,
    self,
    ...
  }: {
    users.defaultUserShell = pkgs.zsh;

    programs.zsh = {
      enable = true;
      # compinit runs in sh/zshrc.d/50-opts.zsh
      enableGlobalCompInit = false;
      # The prompt is defined in sh/zshrc.d/45-prompt.zsh
      promptInit = "";
    };

    # Replaces the manual ssh-agent bootstrap formerly in sh/zshrc.d/80-ssh-agent.zsh.
    # SSH_AUTH_SOCK is exported via environment.extraInit (set-environment).
    programs.ssh = {
      startAgent = true;
      agentTimeout = "24h";
    };

    # Plugins are loaded from sh/zshrc.d, in the order they need
    environment.pathsToLink = [
      "/share/zsh-autosuggestions"
      "/share/zsh-syntax-highlighting"
      "/share/fzf-tab"
    ];

    environment.systemPackages = with pkgs-unstable; [
      zsh-autosuggestions
      zsh-syntax-highlighting
      zsh-fzf-tab
      # Completions are picked up from share/zsh/site-functions
      zsh-completions

      eza

      gum
      glow
      fzf
      delta
      bat

      stow
      jq

      git
      fastfetch
      lf
      yazi
      gh

      pciutils
      usbutils
      lm_sensors

      self.packages.${pkgs.stdenv.hostPlatform.system}.mcal
    ];
  };
}
