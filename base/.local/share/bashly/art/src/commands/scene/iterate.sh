scene=${args[scene]}

path="$ART_CURRENT_PATH/Scenes/$scene"

cd "$path" || exit 1

latest=$(find . -maxdepth 1 -name "$scene*.ntp" | sort -V | tail -n 1)

current_number=$(echo "$latest" | grep -o '[0-9]\+')
echo "Latest version is $current_number"

new_file=$(printf "$scene%02d.ntp" $((current_number + 1)))

cp -vi "$latest" "$new_file"

[ "${args[--open]}" ] && wmspawn "Natron $path/$new_file"
