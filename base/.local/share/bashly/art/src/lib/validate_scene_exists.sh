validate_scene_exists() {
    scene_name="$1"
    [ -d "$ART_CURRENT_PATH/Scenes/$scene_name" ] || echo "Scene $scene_name does not exist"
}
