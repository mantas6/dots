scene=${args[scene]}

path="$ART_CURRENT_PATH/Scenes"

[ "$scene" ] && path="$path/$scene"

eza --icons --tree "$path"
