#!/usr/bin/env zsh
# fzf-tab must load after compinit and before plugins that wrap widgets

[[ -f "$_fzf_tab_dir/fzf-tab.plugin.zsh" ]] && source "$_fzf_tab_dir/fzf-tab.plugin.zsh"
[[ -f "$_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
    && source "$_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
