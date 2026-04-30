for script in "$DOTS_DIR"/sh/zshrc.d/*.zsh; do
    source "$script"
    # echo "$script"
done
