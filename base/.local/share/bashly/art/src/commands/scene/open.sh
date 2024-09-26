scene=${args[scene]}

path="$ART_CURRENT_PATH/Scenes/$scene"

cd "$path" || exit 1

latest=$(find . -maxdepth 1 -name "$scene*.ntp" | sort -V | tail -n 1)

wmspawn "Natron $latest"

