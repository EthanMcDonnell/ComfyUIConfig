WORKSPACE_DIR="/workspace"
COMFYUI_DIR="$WORKSPACE_DIR/ComfyUI"
REPO_DIR="$WORKSPACE_DIR/ComfyUIConfig"

UNCAPTIONED_TRAINING_IMAGE_DIR="$WORKSPACE_DIR/uncaptioned_training_images"
PYTHON_GOOGLE_DRIVE_SCRIPT="$REPO_DIR/gdrive.py"

# (Google Drive folder IDs)
declare -a UNCAPTIONED_TRAINING_IMAGE_GDRIVE_FOLDER=(
    "1-RP3RcQxQIDtvco8CiFexGC_VdRd9WIZ" # Private GDRIVE Folder ID
)

if [ -z "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" ]; then
    echo "Error: GDRIVE_SERVICE_ACCOUNT_JSON_B64 environment variable is not set." >&2
    exit 1
fi

echo "Downloading images from Google Drive..."
if [ ${#UNCAPTIONED_TRAINING_IMAGE_GDRIVE_FOLDER[@]} -gt 0 ]; then
    mkdir -p "$UNCAPTIONED_TRAINING_IMAGE_DIR"
    for folder_id in "${UNCAPTIONED_TRAINING_IMAGE_GDRIVE_FOLDER[@]}"; do
        echo "Downloading files from $folder_id → $UNCAPTIONED_TRAINING_IMAGE_DIR"
        python3 download "$PYTHON_GOOGLE_DRIVE_SCRIPT" "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" "$UNCAPTIONED_TRAINING_IMAGE_DIR" "$folder_id"
    done
else
    echo "No image download google drives specified."
fi 