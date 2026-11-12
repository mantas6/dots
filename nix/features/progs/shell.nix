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
      interactiveShellInit = with pkgs-unstable; ''
        source "${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
        source "${zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        source "${zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
        fpath=("${zsh-completions}/share/zsh/site-functions" $fpath)
      '';
      # The prompt is defined in sh/zshrc.d/45-prompt.zsh
      promptInit = "";
    };

    # Replaces the manual ssh-agent bootstrap formerly in sh/zshrc.d/80-ssh-agent.zsh.
    # SSH_AUTH_SOCK is exported via environment.extraInit (set-environment).
    programs.ssh = {
      startAgent = true;
      agentTimeout = "24h";
    };

    environment.systemPackages = with pkgs-unstable; [
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
