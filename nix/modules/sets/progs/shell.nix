{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  ...
}: let
  name = "progs.shell";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
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

      environment.systemPackages = with pkgs-unstable; [
        starship
        eza

        gum
        glow
        fzf
        delta
        bat

        stow
        jq
        yq-go

        git
        fastfetch
        lf
        yazi
        gh

        pciutils
        usbutils
        lm_sensors
      ];
    })
  ];
}
