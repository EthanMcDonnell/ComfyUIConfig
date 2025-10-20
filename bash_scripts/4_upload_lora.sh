WORKSPACE_DIR="/workspace"
REPO_DIR="$WORKSPACE_DIR/ComfyUIConfig"
ONETRAINER_DIR="$WORKSPACE_DIR/OneTrainer"

SOURCE_LORA_DIR="$ONETRAINER_DIR/models"
PYTHON_GOOGLE_DRIVE_SCRIPT="$REPO_DIR/gdrive.py"

# (Google Drive folder IDs)
LORA_GOOGLE_DRIVE="14rD70432WVhb6rZFcN_TeRzymfze-LiD" # Private GDRIVE Folder ID

if [ -z "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" ]; then
    echo "Error: GDRIVE_SERVICE_ACCOUNT_JSON_B64 environment variable is not set." >&2
    exit 1
fi

echo "Installing Repo Dependencies..."
pip install -r "$REPO_DIR/requirements.txt"

echo "Uploading files from $LORA_DIR → Google Drive"
python3 "$PYTHON_GOOGLE_DRIVE_SCRIPT" upload "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" "$SOURCE_LORA_DIR" "$LORA_GOOGLE_DRIVE"