WORKSPACE_DIR="/workspace"
COMFYUI_DIR="$WORKSPACE_DIR/ComfyUI"
REPO_DIR="$WORKSPACE_DIR/ComfyUIConfig"

COMFY_IMAGE_DIR="$COMFY_DIR/output"
PYTHON_GOOGLE_DRIVE_SCRIPT="$REPO_DIR/gdrive.py"

# (Google Drive folder IDs)
declare -a IMAGES_GDRIVE_FOLDER=(
    "1AS_-MutrsoLsMnsZp7R4Hoe9Sa_fcBhF" # Private GDRIVE Folder ID
)

if [ -z "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" ]; then
    echo "Error: GDRIVE_SERVICE_ACCOUNT_JSON_B64 environment variable is not set." >&2
    exit 1
fi

echo "Uploading images to Google Drive..."
if [ ${#IMAGES_GDRIVE_FOLDER[@]} -gt 0 ]; then
    for folder_id in "${IMAGES_GDRIVE_FOLDER[@]}"; do
        echo "Uploading files from $folder_id → Google Drive"
        python3 upload "$PYTHON_GOOGLE_DRIVE_SCRIPT" "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" "$COMFY_IMAGE_DIR" "$folder_id"
    done
else
    echo "No image upload google drives specified."
fi 