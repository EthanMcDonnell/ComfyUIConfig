#!/bin/bash
# AI Toolkit installation script
# Exit on errors
set -e

# Define directories
WORKSPACE_DIR="/workspace"
AI_TOOLKIT_DIR="$WORKSPACE_DIR/ai-toolkit"
REPO_DIR="$WORKSPACE_DIR/ComfyUIConfig"

# Set Python to 3.12 (AI Toolkit requires Python 3.12)
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1
sudo update-alternatives --set python /usr/bin/python3.12

# --- Function to create venv with a specified Python version ---
create_venv() {
    local APP_DIR="$1"
    local VENV_NAME="$2"
    local PYTHON_VERSION="$3"
    
    echo "Creating virtual environment for $APP_DIR with $PYTHON_VERSION..."
    $PYTHON_VERSION -m venv "$APP_DIR/$VENV_NAME"
    source "$APP_DIR/$VENV_NAME/bin/activate"
    echo "Upgrading pip, setuptools, wheel..."
    pip install --upgrade pip setuptools wheel
}

# --- Install AI Toolkit ---
echo "Cloning ai-toolkit..."
git clone https://github.com/ostris/ai-toolkit.git "$AI_TOOLKIT_DIR"

# Create venv for AI Toolkit using Python 3.12
create_venv "$AI_TOOLKIT_DIR" "venv" "python3.12"

sudo apt update
sudo apt install -y nodejs npm

# Install AI Toolkit dependencies inside venv
echo "Installing ai-toolkit dependencies..."
cd "$AI_TOOLKIT_DIR"

# Install PyTorch with CUDA support first
echo "Installing PyTorch with CUDA support..."
# specific version as outlined in Github issue: https://github.com/ostris/ai-toolkit/issues/484
pip3 install --no-cache-dir torch==2.8.0+cu129 torchvision==0.23.0+cu129 torchaudio==2.8.0+cu129 --index-url https://download.pytorch.org/whl/cu129

# Install AI Toolkit requirements
echo "Installing ai-toolkit requirements..."
pip install -r requirements.txt

# Optional: Copy any custom config files if they exist
if [ -d "$REPO_DIR/aitoolkit_config" ]; then
    echo "Copying custom configuration files..."
    cp -r "$REPO_DIR/aitoolkit_config/"* "$AI_TOOLKIT_DIR/config/"
fi

deactivate

echo "AI Toolkit installation complete."
echo "To run AI Toolkit: source /workspace/ai-toolkit/venv/bin/activate && cd /workspace/ai-toolkit/ui && npm run build && npm start"

echo "Example training: python run.py config/examples/train_lora_flux_24gb.yaml"