#!/bin/bash
# OneTrainer installation script
# Exit on errors
set -e

# Define directories
WORKSPACE_DIR="/workspace"
ONE_TRAINER_DIR="$WORKSPACE_DIR/one-trainer"
REPO_DIR="$WORKSPACE_DIR/ComfyUIConfig"

# Set Python to 3.12
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.12 2
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

# --- Install One-Trainer ---
echo "Cloning one-trainer..."
git clone https://github.com/Nerogar/OneTrainer.git "$ONE_TRAINER_DIR"

# Create venv for OneTrainer using Python 3.12
create_venv "$ONE_TRAINER_DIR" "venv" "python3.12"

# Install One-Trainer dependencies inside venv
echo "Installing one-trainer dependencies..."
sudo apt-get update
sudo apt-get install -y python3-tk

cd "$ONE_TRAINER_DIR"
bash "$ONE_TRAINER_DIR/install.sh"
bash "$ONE_TRAINER_DIR/update.sh"
pip install deepdiff
deactivate

cp -r "$REPO_DIR/one-trainer-config/"* "$ONE_TRAINER_DIR/"

echo "One-trainer installation complete."
echo "To run One-Trainer: export DISPLAY=:1 && source $ONE_TRAINER_DIR/venv/bin/activate && bash $ONE_TRAINER_DIR/start-ui.sh"