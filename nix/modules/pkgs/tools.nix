{pkgs-unstable, ...}: {
  environment.systemPackages = with pkgs-unstable; [
    vim
    wget
    curl
    git
    fastfetch
    lf
    yazi
    bat
    stow
    zoxide
    starship
    eza
    trash-cli
    gh
    gum
    glow
    fzf
    delta
    unzip
    sysz
    htop
    btop
    jq

    # zsh-autosuggestions
    # zsh-completions
    # zsh-syntax-highlighting
    # zsh-fzf-tab

    pciutils
  ];

  environment.etc."share/zsh/zsh-autosuggestions.zsh".source
    = "${pkgs-unstable.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";

  environment.etc."share/zsh/zsh-syntax-highlighting.zsh".source
    = "${pkgs-unstable.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";

  environment.etc."share/zsh/fzf-tab.plugin.zsh".source
    = "${pkgs-unstable.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh";

  environment.etc."share/zsh/completions".source
    = "${pkgs-unstable.zsh-completions}/share/zsh";

  programs.nh = {
    enable = true;
    flake = "/home/mantas/Repos/dotfiles";
  };
}
