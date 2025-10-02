#!/usr/bin/env zsh

[ "$(uname)" != "Darwin" ] && return

source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fpath=("$(brew --prefix)/share/zsh-completions" $fpath)

fzf_tab_path="$HOME/.local/state/zsh/fzf-tab"

if [ -d "$fzf_tab_path" ]; then
    source "$fzf_tab_path/fzf-tab.plugin.zsh"
fi

unset fzf_tab_path

# https://github.com/Aloxaf/fzf-tab?tab=readme-ov-file#install
# https://formulae.brew.sh/formula/zsh-completions
