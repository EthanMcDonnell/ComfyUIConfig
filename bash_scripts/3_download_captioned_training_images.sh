WORKSPACE_DIR="/workspace"
COMFYUI_DIR="$WORKSPACE_DIR/ComfyUI"
REPO_DIR="$WORKSPACE_DIR/ComfyUIConfig"
ONETRAINER_DIR="$WORKSPACE_DIR/OneTrainer"

CAPTIONED_TRAINING_IMAGE_DIR="$ONETRAINER_DIR/training_images"
PYTHON_GOOGLE_DRIVE_SCRIPT="$REPO_DIR/gdrive.py"

# (Google Drive folder IDs)
declare -a CAPTIONED_TRAINING_IMAGE_GDRIVE_FOLDER=(
    "1asuDXv0AGCDNKYKCcnJVyW3kULkMlI1F" # Private GDRIVE Folder ID
)

if [ -z "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" ]; then
    echo "Error: GDRIVE_SERVICE_ACCOUNT_JSON_B64 environment variable is not set." >&2
    exit 1
fi

echo "Downloading images from Google Drive..."
if [ ${#CAPTIONED_TRAINING_IMAGE_GDRIVE_FOLDER[@]} -gt 0 ]; then
    mkdir -p "$CAPTIONED_TRAINING_IMAGE_DIR"
    for folder_id in "${CAPTIONED_TRAINING_IMAGE_GDRIVE_FOLDER[@]}"; do
        echo "Downloading files from $folder_id → $CAPTIONED_TRAINING_IMAGE_DIR"
        python3 download "$PYTHON_GOOGLE_DRIVE_SCRIPT" "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" "$CAPTIONED_TRAINING_IMAGE_DIR" "$folder_id"
    done
else
    echo "No image download google drives specified."
fi 