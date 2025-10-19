#!/bin/bash

# --- Config ---
# List of custom nodes to install. Use git clone links.
declare -a CUSTOM_NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/crystian/comfyui-crystools.git"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
)

# List of models to download. Each entry is a [URL, OutputPath].
# CyberRealistic, CyberRealistic Pony, JibMix, Juggernaut XL
declare -a MODELS=(
    "https://civitai.com/api/download/models/2152184?type=Model&format=SafeTensor&size=pruned&fp=fp16"
    "https://civitai.com/api/download/models/2255476?type=Model&format=SafeTensor&size=pruned&fp=fp16"
    "https://civitai.com/api/download/models/1966530?type=Model&format=SafeTensor&size=pruned&fp=fp16"
    "https://civitai.com/api/download/models/1759168?type=Model&format=SafeTensor&size=full&fp=fp16"
)

# List of LoRAs to download. Each entry is a [URL, OutputPath].
declare -a LORAS=(
)

# --- 0. Verify Correct Directory ---
echo "Verifying execution directory..."
if [ "$PWD" != "/workspace" ]; then
  echo "Error: This script must be run from the /workspace directory." >&2
  echo "Current directory is '$PWD'. Aborting." >&2
  exit 1
fi
echo "✅  Directory confirmed: /workspace"

# --- 1. Install ComfyUI ---
echo "Cloning ComfyUI repository..."
git clone https://github.com/comfyanonymous/ComfyUI.git

cd ComfyUI

# --- 2. Install ComfyUI Dependencies ---
echo "Installing ComfyUI Python dependencies..."
pip install -r requirements.txt

# --- 3. Install Custom Nodes ---
echo "Installing custom nodes..."
cd custom_nodes
for url in "${CUSTOM_NODES[@]}"; do
    if [ ! -z "$url" ]; then
        # Get repo name
        repo_name=$(basename "$url" .git)
        # Clone the repo
        git clone "$url"
        # Install requirements.txt if exists
        if [ -f "$repo_name/requirements.txt" ]; then
            echo "Installing requirements for $repo_name..."
            pip install -r "$repo_name/requirements.txt"
        fi
    fi
done
cd ..

# --- 4. Copy Workflows from repo into ComfyUI ---
echo "Copying workflows from repository into ComfyUI workflows folder..."
REPO_WORKFLOWS_DIR="../ComfyUIConfig/workflows"
TARGET_WORKFLOWS_DIR="./user/default/workflows"
if [ -d "$REPO_WORKFLOWS_DIR" ]; then
    mkdir -p "$TARGET_WORKFLOWS_DIR"
    cp -a "$REPO_WORKFLOWS_DIR/." "$TARGET_WORKFLOWS_DIR/"
    echo "✅ Workflows copied to $TARGET_WORKFLOWS_DIR"
else
    echo "No workflows directory found at $REPO_WORKFLOWS_DIR; skipping."
fi


# --- 5. Download Models ---
echo "Downloading models..."
for item in "${MODELS[@]}"; do
    IFS=',' read -r url output_path <<< "$item"
    if [ ! -z "$url" ]; then
        wget -c "$url" -O "$output_path"
    fi
done

# --- 6. Download LoRAs ---
echo "Downloading LoRAs..."
for item in "${LORAS[@]}"; do
    IFS=',' read -r url output_path <<< "$item"
    if [ ! -z "$url" ]; then
        wget -c "$url" -O "$output_path"
    fi
done

# --- 7. Launch ComfyUI ---
echo "Setup complete! Launching ComfyUI... 🚀"
python main.py --listen 0.0.0.0
