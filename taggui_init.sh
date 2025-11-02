#!/bin/bash
# TagGUI installation script
# Exit on errors
set -e

# Define directories
WORKSPACE_DIR="/workspace"
TAGGUI_DIR="$WORKSPACE_DIR/taggui"

# Set Python to 3.11
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1
sudo update-alternatives --set python /usr/bin/python3.11

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

# --- Install TagGUI ---
echo "Cloning TagGUI..."
git clone https://github.com/jhc13/taggui.git "$TAGGUI_DIR"

# Create venv for TagGUI using Python 3.11
create_venv "$TAGGUI_DIR" "venv" "python3.11"

# Install TagGUI dependencies inside venv
cd "$TAGGUI_DIR"
pip install torch==2.8.0+cu128 --index-url https://download.pytorch.org/whl/cu128
pip install -r requirements.txt

echo "Downloading WD-VIT-Tagger model..."
mkdir -p "$TAGGUI_DIR/models"
curl -L -o "$TAGGUI_DIR/models/wd-vit-tagger-v3.safetensors" "https://huggingface.co/SmilingWolf/wd-vit-tagger-v3/resolve/main/model.safetensors"

deactivate
sudo update-alternatives --set python /usr/bin/python3.12
echo "TagGUI installation complete."
echo "To run TagGUI: export DISPLAY=:1 && source $TAGGUI_DIR/venv/bin/activate && python $TAGGUI_DIR/taggui/run_gui.py"