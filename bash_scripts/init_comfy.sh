#!/bin/bash
# Setup to work with runpod
# Expose port 8188 for comfyui access
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


# Custom nodes
declare -a CUSTOM_NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/crystian/comfyui-crystools.git"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
    "https://github.com/rgthree/rgthree-comfy.git"
    "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git"
    "https://github.com/kijai/ComfyUI-KJNodes.git"
    "https://github.com/ltdrdata/was-node-suite-comfyui.git"
)

# Models
declare -a MODELS=(
    # "https://civitai.com/api/download/models/2152184?type=Model&format=SafeTensor&size=pruned&fp=fp16,$COMFYUI_DIR/models/checkpoints/cyberrealistic.safetensors"
    # # "https://civitai.com/api/download/models/2255476?type=Model&format=SafeTensor&size=pruned&fp=fp16,$COMFYUI_DIR/models/checkpoints/cyberrealistic_pony.safetensors"
    "https://civitai.com/api/download/models/1966530?type=Model&format=SafeTensor&size=pruned&fp=fp16,$COMFYUI_DIR/models/checkpoints/jibmix.safetensors"
    "https://civitai.com/api/download/models/1759168?type=Model&format=SafeTensor&size=full&fp=fp16,$COMFYUI_DIR/models/checkpoints/juggernaut_xl.safetensors"
    "https://civitai.com/api/download/models/1920523?type=Model&format=SafeTensor&size=pruned&fp=fp16,$COMFYUI_DIR/models/checkpoints/epicrealismXL_vxviiCrystalclear.safetensors"
    "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_fp8_e4m3fn.safetensors,$COMFYUI_DIR/models/diffusion_models/qwen_image_fp8_e4m3fn.safetensors"
    "https://huggingface.co/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_edit_2509_fp8_e4m3fn.safetensors,$COMFYUI_DIR/models/diffusion_models/qwen_image_edit_2509_fp8_e4m3fn.safetensors"
    "https://huggingface.co/QuantStack/Wan2.2-T2V-A14B-GGUF/resolve/main/LowNoise/Wan2.2-T2V-A14B-LowNoise-Q8_0.gguf,$COMFYUI_DIR/models/Wan2.2-T2V-A14B-LowNoise-Q8_0.gguf"
    "https://huggingface.co/QuantStack/Wan2.2-T2V-A14B-GGUF/resolve/main/HighNoise/Wan2.2-T2V-A14B-HighNoise-Q8_0.gguf,$COMFYUI_DIR/models/Wan2.2-T2V-A14B-HighNoise-Q8_0.gguf"
)

# --- VAEs ---
declare -a VAES=(
    "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors,$VAE_DIR/qwen_image_vae.safetensors"
)

declare -a TEXT_ENCODERS=(
    "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors,$TEXT_ENCODERS_DIR/qwen_2.5_vl_7b_fp8_scaled.safetensors"
)

# LoRAs
# <lora:PerfectEyesXL:1.0>
# <lora:add-detail-xl:3> [-3, 3]
declare -a LORAS=(
    "https://civitai.com/api/download/models/128461?type=Model&format=SafeTensor,$LORAS_DIR/PerfectEyesXL.safetensors"
    "https://civitai.com/api/download/models/135867?type=Model&format=SafeTensor,$LORAS_DIR/add_detail_xl.safetensors"
    "https://huggingface.co/lightx2v/Qwen-Image-Lightning/resolve/main/Qwen-Image-Lightning-4steps-V2.0.safetensors,$LORAS_DIR/Qwen-Image-Lightning-4steps-V2.0.safetensors"
    "https://civitai.com/api/download/models/2124694?type=Model&format=Diffusers,$LORAS_DIR/instareal.zip"
    "https://civitai.com/api/download/models/2066914?type=Model&format=SafeTensor,$LORAS_DIR/lenovo.safetensors"
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


# --- Install base dependencies ---
echo "📦 Installing Repo dependencies..."
pip install -r "$REPO_DIR/requirements.txt" --quiet

# --- Clone ComfyUI if missing ---
if [ ! -d "$COMFYUI_DIR" ]; then
    echo "🧠 Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
    cd "$COMFYUI_DIR"
    pip install -r "$COMFYUI_DIR/requirements.txt"
else
    echo "✅ ComfyUI already exists, skipping clone."
fi


sudo apt update
sudo apt install aria2 -y

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
        curl -L --retry 3 --retry-all-errors --retry-delay 2 --fail --continue-at - \
            -H "Authorization: Bearer ${CIVITAI_API_KEY}" \
            -o "$output_path" \
            "$url"
    else
        aria2c -x 16 -s 16 -k 1M -o "$(basename "$output_path")" -d "$(dirname "$output_path")" "$url"
    fi
}

# --- Downloads ---
download_category() {
    local category_name="$1"
    shift
    local arr=("$@")

    echo "📂 Downloading $category_name..."
    for item in "${arr[@]}"; do
        IFS=',' read -r url output_path <<< "$item"
        [ -z "$url" ] && continue
        download_file "$url" "$output_path"
    done
}


# --- Custom Nodes ---
echo "🧩 Installing custom nodes..."
cd "$COMFYUI_DIR/custom_nodes"
for url in "${CUSTOM_NODES[@]}"; do
    repo_name=$(basename "$url" .git)
    if [ -d "$repo_name" ]; then
        echo "⏭️  Skipping existing node: $repo_name"
        continue
    fi
    echo "🔗 Cloning $repo_name..."
    git clone "$url" "$repo_name"
    if [ -f "$repo_name/requirements.txt" ]; then
    echo "Installing requirements for $repo_name..."
        pip install -r "$repo_name/requirements.txt" --quiet
    fi
done
cd "$COMFYUI_DIR"

# --- Copy Workflows ---
if [ -d "$REPO_WORKFLOWS_DIR" ]; then
    mkdir -p "$TARGET_WORKFLOWS_DIR"
    cp -an "$REPO_WORKFLOWS_DIR/." "$TARGET_WORKFLOWS_DIR/"
    echo "✅ Workflows copied to $TARGET_WORKFLOWS_DIR"
fi

   

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

