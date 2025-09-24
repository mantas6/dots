{
  pkgs,
  pkgs-unstable,
  config,
  lib,
  ...
}: {
  options = {
    features.useZshShell = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "Enable zsh shell with plugins";
    };
  };

  config = lib.mkIf (config.features.useZshShell) {
    users.defaultUserShell = pkgs.zsh;

    programs.zsh = {
      enable = true;
      interactiveShellInit = with pkgs-unstable; ''
        source "${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
        source "${zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        source "${zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
        fpath=("${zsh-completions}/share/zsh/site-functions" $fpath)
      '';
    };
  };
}
