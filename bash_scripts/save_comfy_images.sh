WORKSPACE_DIR="/workspace"
COMFYUI_DIR="$WORKSPACE_DIR/ComfyUI"
REPO_DIR="$WORKSPACE_DIR/ComfyUIConfig"

INPUT_COMFY_IMAGE_DIR="$COMFY_DIR/output"
PYTHON_GOOGLE_DRIVE_SCRIPT="$REPO_DIR/gdrive.py"

# (Google Drive folder IDs)
IMAGES_GDRIVE_FOLDER="1AS_-MutrsoLsMnsZp7R4Hoe9Sa_fcBhF" # Private GDRIVE Folder ID

if [ -z "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" ]; then
    echo "Error: GDRIVE_SERVICE_ACCOUNT_JSON_B64 environment variable is not set." >&2
    exit 1
fi

echo "Uploading images to Google Drive..."
python3 "$PYTHON_GOOGLE_DRIVE_SCRIPT" upload "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" "$INPUT_COMFY_IMAGE_DIR" "$IMAGES_GDRIVE_FOLDER"