scene=${args[scene]}
subscene=${args[subscene]}

read_dir="$ART_CURRENT_PATH/Scenes/$scene/Read"

trash -v "$read_dir/$subscene"
