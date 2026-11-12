# Drop duplicate PATH entries added below
typeset -U PATH

for script in "$DOTS_DIR"/sh/zprofile.d/*.zsh; do
    # echo "$script"
    source "$script"
done
