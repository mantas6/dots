name=${args[name]}

path="$ART_CURRENT_PATH/Scenes/$name"

[ -d "$path" ] && echo "Scene $name already exists" && exit 1

mkdir -pv "$path"
mkdir -p "$path/Read"
mkdir -p "$path/Write"
mkdir -p "$path/Intermediate"
