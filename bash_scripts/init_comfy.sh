#!/bin/bash
# Setup to work with runpod
# Expose port 8188 for comfyui access
set -e
# --- Config ---
WORKSPACE_DIR="/workspace"
COMFYUI_DIR="$WORKSPACE_DIR/ComfyUI"
REPO_DIR="$WORKSPACE_DIR/ComfyUIConfig"


LORAS_DIR="$COMFYUI_DIR/models/loras"
REPO_WORKFLOWS_DIR="$REPO_DIR/workflows"
TARGET_WORKFLOWS_DIR="$COMFYUI_DIR/user/default/workflows"
PYTHON_GOOGLE_DRIVE_SCRIPT="$REPO_DIR/gdrive.py"


# Custom nodes
declare -a CUSTOM_NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/crystian/comfyui-crystools.git"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
    "https://github.com/rgthree/rgthree-comfy.git"

)

# Models
declare -a MODELS=(
    "https://civitai.com/api/download/models/2152184?type=Model&format=SafeTensor&size=pruned&fp=fp16,$COMFYUI_DIR/models/checkpoints/cyberrealistic.safetensors"
    "https://civitai.com/api/download/models/2255476?type=Model&format=SafeTensor&size=pruned&fp=fp16,$COMFYUI_DIR/models/checkpoints/cyberrealistic_pony.safetensors"
    "https://civitai.com/api/download/models/1966530?type=Model&format=SafeTensor&size=pruned&fp=fp16,$COMFYUI_DIR/models/checkpoints/jibmix.safetensors"
    "https://civitai.com/api/download/models/1759168?type=Model&format=SafeTensor&size=full&fp=fp16,$COMFYUI_DIR/models/checkpoints/juggernaut_xl.safetensors"
)

# LoRAs
declare -a LORAS=(
    "https://civitai.com/api/download/models/128461?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/135867?type=Model&format=SafeTensor"
)

# Personal LoRAs (Google Drive file IDs)
declare -a PERSONAL_LORAS_GDRIVE_FOLDER=(
    "14rD70432WVhb6rZFcN_TeRzymfze-LiD" # Private GDRIVE Folder ID
)


# --- 0. Checking Prerequisites ---
if [ "$PWD" != "$WORKSPACE_DIR" ]; then
    echo "Error: This script must be run from $WORKSPACE_DIR." >&2
    exit 1
fi
echo "✅ Directory confirmed: $WORKSPACE_DIR"

if [ -z "$CIVITAI_API_KEY" ]; then
    echo "Error: CIVITAI_API_KEY environment variable is not set." >&2
    exit 1
fi

if [ -z "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" ]; then
    echo "Error: GDRIVE_SERVICE_ACCOUNT_JSON_B64 environment variable is not set." >&2
    exit 1
fi


echo "Installing Repo Dependencies..."
pip install -r "$REPO_DIR/requirements.txt"


# --- 1. Install ComfyUI ---
echo "Cloning ComfyUI repository..."
git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
cd "$COMFYUI_DIR"

# --- 2. Install Dependencies ---
echo "Installing ComfyUI Python dependencies..."
pip install -r "$COMFYUI_DIR/requirements.txt"

# --- 3. Install Custom Nodes ---
echo "Installing custom nodes..."
cd "$COMFYUI_DIR/custom_nodes"
for url in "${CUSTOM_NODES[@]}"; do
    [ -z "$url" ] && continue
    repo_name=$(basename "$url" .git)
    git clone "$url" "$COMFYUI_DIR/custom_nodes/$repo_name"
    if [ -f "$COMFYUI_DIR/custom_nodes/$repo_name/requirements.txt" ]; then
        echo "Installing requirements for $repo_name..."
        pip install -r "$COMFYUI_DIR/custom_nodes/$repo_name/requirements.txt"
    fi
done
cd "$COMFYUI_DIR"

# --- 4. Copy Workflows ---

if [ -d "$REPO_WORKFLOWS_DIR" ]; then
    mkdir -p "$TARGET_WORKFLOWS_DIR"
    cp -a "$REPO_WORKFLOWS_DIR/." "$TARGET_WORKFLOWS_DIR/"
    echo "✅ Workflows copied to $TARGET_WORKFLOWS_DIR"
fi

# --- 5. Download Models ---
echo "Downloading models..."
for item in "${MODELS[@]}"; do
    IFS=',' read -r url output_path <<< "$item"
    [ -z "$url" ] && continue
    mkdir -p "$(dirname "$output_path")"
    echo "Downloading $url → $output_path"
    curl -L -H "Authorization: Bearer $CIVITAI_API_KEY" "$url" -o "$output_path"
done

# --- 6. Download LoRAs ---
echo "Downloading LoRAs..."
for item in "${LORAS[@]}"; do
    IFS=',' read -r url output_path <<< "$item"
    [ -z "$url" ] && continue
    mkdir -p "$(dirname "$output_path")"
    echo "Downloading $url → $output_path"
    curl -L -H "Authorization: Bearer $CIVITAI_API_KEY" "$url" -o "$output_path"
done

# --- 7. Download Personal LoRAs ---
echo "Downloading personal LoRAs from Google Drive..."
if [ ${#PERSONAL_LORAS_GDRIVE_FOLDER[@]} -gt 0 ]; then
    mkdir -p "$LORAS_DIR"
    for folder_id in "${PERSONAL_LORAS_GDRIVE_FOLDER[@]}"; do
        echo "Downloading files from $folder_id → $LORAS_DIR"
        python3 "$PYTHON_GOOGLE_DRIVE_SCRIPT" download "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" "$LORAS_DIR" "$folder_id"
    done
else
    echo "No personal LoRAs specified."
fi

# --- 8. Launch ComfyUI ---
echo "Setup complete! Launching ComfyUI... 🚀"
python3 "$COMFYUI_DIR/main.py" --listen 0.0.0.0
