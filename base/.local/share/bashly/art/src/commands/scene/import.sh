scene=${args[scene]}
subscene=${args[subscene]}
source=${args[source]}

extension="${source##*.}"

read_dir="$ART_CURRENT_PATH/Scenes/$scene/Read"
mkdir -p "$read_dir"

case "$extension" in
    mp4)
        mkdir "$read_dir/$subscene"
        cp -vi "$source" "$read_dir/$subscene/$subscene.$extension"
        ;;
    *)
        cp -vi "$source" "$read_dir/$subscene.$extension"
        ;;
esac
