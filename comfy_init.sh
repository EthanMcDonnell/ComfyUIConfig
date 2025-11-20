#!/bin/bash
# Setup to work with runpod
# Expose port 8188 for comfyui access
# eval "$COMFYINIT wan qwen sdxl"

set -e
# --- Config ---
WORKSPACE_DIR="/workspace"
COMFYUI_DIR="$WORKSPACE_DIR/ComfyUI"
REPO_DIR="$WORKSPACE_DIR/ComfyUIConfig"

TEXT_ENCODERS_DIR="$COMFYUI_DIR/models/text_encoders"
VAE_DIR="$COMFYUI_DIR/models/vae"
LORAS_DIR="$COMFYUI_DIR/models/loras"
REPO_WORKFLOWS_DIR="$REPO_DIR/workflows"
TARGET_WORKFLOWS_DIR="$COMFYUI_DIR/user/default/workflows"
PYTHON_GOOGLE_DRIVE_SCRIPT="$REPO_DIR/gdrive.py"

# --- Config identifiers (no need for -c) ---
CONFIG_IDS=("WAN" "QWEN" "SDXL")  # Add as many as you want
CONFIG_DIR="$REPO_DIR/config"  # Folder where your JSON files live

# Custom nodes
declare -a CUSTOM_NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/crystian/comfyui-crystools.git"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
    "https://github.com/rgthree/rgthree-comfy.git"
    "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git"
    "https://github.com/kijai/ComfyUI-KJNodes.git"
    "https://github.com/ltdrdata/was-node-suite-comfyui.git"
    "https://github.com/city96/ComfyUI-GGUF.git"
    "https://github.com/giriss/comfy-image-saver.git"
    "https://github.com/ClownsharkBatwing/RES4LYF.git"
    https://github.com/hgabha/WWAA-CustomNodes.git
    https://github.com/ltdrdata/ComfyUI-Impact-Pack # sdxl detailer
    https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git # sdxl detailer
    https://github.com/yolain/ComfyUI-Easy-Use # sdxl detailer
    https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git # sdxl detailer
)
MODELS=()
VAES=()
TEXT_ENCODERS=()
LORAS=()

# Personal LoRAs (Google Drive file IDs)
declare -a PERSONAL_LORAS_GDRIVE_FOLDER=(
    "14rD70432WVhb6rZFcN_TeRzymfze-LiD" # Private GDRIVE Folder ID
)

# --- 0. Checking Prerequisites ---

cd "$WORKSPACE_DIR"
echo "✅ Directory confirmed: $WORKSPACE_DIR"

if [ -z "$CIVITAI_API_KEY" ]; then
    echo "Error: CIVITAI_API_KEY environment variable is not set." >&2
    exit 1
fi

if [ -z "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" ]; then
    echo "Error: GDRIVE_SERVICE_ACCOUNT_JSON_B64 environment variable is not set." >&2
    exit 1
fi

# --- Check arguments ---
if [ $# -lt 1 ]; then
    echo "Usage: $0 <config_id1> [<config_id2> ...]"
    exit 1
fi
CONFIG_IDS=("$@")  # all arguments
for id in "${CONFIG_IDS[@]}"; do
    cfg_file="$CONFIG_DIR/${id,,}.json"  # ${id,,} converts to lowercase (WAN → wan.json)
    
    if [ ! -f "$cfg_file" ]; then
        echo "❌ Config not found: $cfg_file"
        exit 1
    fi

    # Merge arrays from JSON
    MODELS+=($(jq -r '.models[]?' "$cfg_file"))
    VAES+=($(jq -r '.vaes[]?' "$cfg_file"))
    TEXT_ENCODERS+=($(jq -r '.text_encoders[]?' "$cfg_file"))
    LORAS+=($(jq -r '.loras[]?' "$cfg_file"))
done

# --- Install base dependencies ---
echo "📦 Installing system dependencies..."
sudo apt update
sudo apt install -y aria2 unzip

echo "📦 Installing Python dependencies..."
pip install -q -r "$REPO_DIR/requirements.txt"

# --- Clone ComfyUI if missing ---
if [ ! -d "$COMFYUI_DIR" ]; then
    echo "🧠 Cloning ComfyUI..."
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
else
    echo "✅ ComfyUI already exists, skipping clone."
fi

pip install -q -r "$COMFYUI_DIR/requirements.txt"

# if [ ! -d "SageAttention" ]; then
#     echo "🧠 Cloning SageAttention..."
#     git clone --depth 1 https://github.com/thu-ml/SageAttention.git
#     cd SageAttention 
#     python setup.py install
#     cd ..
# else
#     echo "✅ SageAttention already exists, skipping clone."
# fi

# --- Download helper ---
download_file() {
    local url="$1"
    local output_path="$2"
    mkdir -p "$(dirname "$output_path")"

    if [ -f "$output_path" ]; then
        echo "⏭️  Skipping existing file: $output_path"
        return
    fi

    echo "⬇️  Downloading $url → $output_path"
    if [[ "$url" == *"civitai.com"* ]]; then
        # Use curl for CivitAI with proper header handling
        curl -L --retry 3 --retry-all-errors --retry-delay 2 --fail --continue-at - \
            -H "Authorization: Bearer ${CIVITAI_API_KEY}" \
            -o "$output_path" \
            "$url"
    else
        # Standard aria2c for other sources
        aria2c \
            --console-log-level=warn \
            --max-connection-per-server=16 \
            --split=16 \
            --min-split-size=1M \
            --max-concurrent-downloads=5 \
            --file-allocation=none \
            --allow-overwrite=false \
            --auto-file-renaming=false \
            --continue=true \
            --max-tries=5 \
            --retry-wait=3 \
            --out="$(basename "$output_path")" \
            --dir="$(dirname "$output_path")" \
            "$url"
    fi
    
    # --- Auto-extract ZIP files ---
    if [[ "$output_path" == *.zip ]]; then
        echo "🗜️  Extracting $output_path..."
        unzip -o "$output_path" -d "$(dirname "$output_path")"
        echo "✅ Extracted to $(dirname "$output_path")"
    fi
}

# --- Sequential download wrapper (OPTIMIZED FOR BANDWIDTH) ---
download_category() {
    local category_name="$1"
    shift
    local arr=("$@")

    if [ ${#arr[@]} -eq 0 ]; then
        return
    fi

    echo "📂 Downloading $category_name..."
    
    # Download sequentially to maximize bandwidth per file
    for item in "${arr[@]}"; do
        IFS=',' read -r url output_path <<< "$item"
        [ -z "$url" ] && continue
        download_file "$url" "$output_path"
    done
}

# --- Custom Nodes (parallel clone - these benefit from parallelization) ---
echo "🧩 Installing custom nodes..."
cd "$COMFYUI_DIR/custom_nodes"

# Clone repos in parallel (small files, not bandwidth-limited)
echo "${CUSTOM_NODES[@]}" | tr ' ' '\n' | xargs -P 4 -I {} bash -c '
    url="{}"
    repo_name=$(basename "$url" .git)
    if [ -d "$repo_name" ]; then
        echo "⏭️  Skipping existing node: $repo_name"
        exit 0
    fi
    echo "🔗 Cloning $repo_name..."
    git clone --depth 1 "$url" "$repo_name"
'

# Install requirements sequentially (to avoid pip conflicts)
for url in "${CUSTOM_NODES[@]}"; do
    repo_name=$(basename "$url" .git)
    if [ -f "$repo_name/requirements.txt" ]; then
        echo "📦 Installing requirements for $repo_name..."
        pip install -q -r "$repo_name/requirements.txt"
    fi
done

cd "$COMFYUI_DIR"

# --- Copy Workflows ---
if [ -d "$REPO_WORKFLOWS_DIR" ]; then
    mkdir -p "$TARGET_WORKFLOWS_DIR"
    cp -an "$REPO_WORKFLOWS_DIR/." "$TARGET_WORKFLOWS_DIR/"
    echo "✅ Workflows copied to $TARGET_WORKFLOWS_DIR"
fi

# --- Download all categories (SEQUENTIAL for full bandwidth) ---
download_category "Models" "${MODELS[@]}"
download_category "VAEs" "${VAES[@]}"
download_category "Text Encoders" "${TEXT_ENCODERS[@]}"
download_category "LoRAs" "${LORAS[@]}"

# --- Personal LoRAs ---
if [ ${#PERSONAL_LORAS_GDRIVE_FOLDER[@]} -gt 0 ]; then
    echo "📁 Downloading personal LoRAs from Google Drive..."
    mkdir -p "$LORAS_DIR"
    for folder_id in "${PERSONAL_LORAS_GDRIVE_FOLDER[@]}"; do
        echo "Downloading files from $folder_id → $LORAS_DIR"
        python3 "$PYTHON_GOOGLE_DRIVE_SCRIPT" download "$GDRIVE_SERVICE_ACCOUNT_JSON_B64" "$LORAS_DIR" "$folder_id"
    done
else
    echo "ℹ️  No personal LoRAs specified."
fi

# --- Launch hint ---
echo ""
echo "✅ Setup complete!"
echo "To start ComfyUI, run:"
echo "👉  python3 ComfyUI/main.py --listen"
echo ""
echo "You can re-run this script anytime — it will skip already installed content."