name=${args[name]}
path="$ART_PROJECTS_PATH/$name"

[ -d "$path" ] && echo "Project $name already exists" && exit 1

mkdir -p "$path"
