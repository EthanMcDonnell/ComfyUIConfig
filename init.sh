#!/bin/bash

# --- Config ---
# List of custom nodes to install. Use git clone links.
declare -a CUSTOM_NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/crystian/comfyui-crystools.git"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
)

# List of models to download. Each entry is a [URL, OutputPath].
declare -a MODELS=(
    "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors,./models/checkpoints/sd_xl_base_1.0.safetensors"
    "https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors,./models/checkpoints/sd_xl_refiner_1.0.safetensors"
    "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors,./models/vae/sdxl_vae.safetensors"
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

# --- 2. Install Dependencies ---
echo "Installing Python dependencies..."
pip install -r requirements.txt

# --- 3. Install Custom Nodes ---
echo "Installing custom nodes..."
cd custom_nodes
for url in "${CUSTOM_NODES[@]}"; do
    if [ ! -z "$url" ]; then
        git clone "$url"
    fi
done
cd ..

# --- 4. Download Models ---
echo "Downloading models..."
for item in "${MODELS[@]}"; do
    IFS=',' read -r url output_path <<< "$item"
    if [ ! -z "$url" ]; then
        wget -c "$url" -O "$output_path"
    fi
done

# --- 5. Download LoRAs ---
echo "Downloading LoRAs..."
for item in "${LORAS[@]}"; do
    IFS=',' read -r url output_path <<< "$item"
    if [ ! -z "$url" ]; then
        wget -c "$url" -O "$output_path"
    fi
done

# --- 6. Launch ComfyUI ---
echo "Setup complete! Launching ComfyUI... 🚀"
python main.py --listen 0.0.0.0