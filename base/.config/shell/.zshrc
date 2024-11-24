# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/shell/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

for script in "$HOME"/.config/shell/zshrc.d/*.zsh; do
    source "$script"
done

# To customize prompt, run `p10k configure` or edit ~/.config/shell/.p10k.zsh.
[[ ! -f ~/.config/shell/.p10k.zsh ]] || source ~/.config/shell/.p10k.zsh
