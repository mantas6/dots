#!/usr/bin/env zsh
# Plugin locations; loaded by 55-plugins.zsh and 99-syntax-highlighting.zsh

if [[ $OSTYPE == darwin* ]]; then
    _plugins_dir="$HOMEBREW_PREFIX/share"
    _fzf_tab_dir="$HOME/.local/state/zsh/fzf-tab"
    # Must be on fpath before compinit
    fpath=("$_plugins_dir/zsh-completions" $fpath)
else
    # Linked by nix/features/progs/shell.nix
    _plugins_dir=/run/current-system/sw/share
    _fzf_tab_dir="$_plugins_dir/fzf-tab"
fi

# https://github.com/Aloxaf/fzf-tab?tab=readme-ov-file#install
# https://formulae.brew.sh/formula/zsh-completions
