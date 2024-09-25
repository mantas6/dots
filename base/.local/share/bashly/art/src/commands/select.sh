name=${args[name]}
path="$ART_PROJECTS_PATH/$name"

[ ! -d "$path" ] && echo "Project $name does not exist" && exit 1

[ -e "$ART_CURRENT_PATH" ] && [ ! -L "$ART_CURRENT_PATH" ] \
    && echo "Target folder is not a symlink. Exiting." && exit 1

rm -f "$ART_CURRENT_PATH"
ln -sfv "$path" "$ART_CURRENT_PATH"
