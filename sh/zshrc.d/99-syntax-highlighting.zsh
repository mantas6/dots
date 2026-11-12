#!/usr/bin/env zsh
# Must load last, after all widgets are defined

[[ -f "$_plugins_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
    && source "$_plugins_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

unset _plugins_dir _fzf_tab_dir
