#!/bin/bash
# Expose port 5000 for gui access
# Exit on errors
set -e

# Define directories
WORKSPACE_DIR="/workspace"
ONE_TRAINER_DIR="$WORKSPACE_DIR/one-trainer"
TAGGUI_DIR="$WORKSPACE_DIR/taggui"

sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

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
    deactivate
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
source "$ONE_TRAINER_DIR/venv/bin/activate"
bash "$ONE_TRAINER_DIR/install.sh"
deactivate
echo "One-trainer installation complete."

# --- Install TagGUI ---
echo "Cloning TagGUI..."
git clone https://github.com/jhc13/taggui.git "$TAGGUI_DIR"

# Create venv for TagGUI using Python 3.11
create_venv "$TAGGUI_DIR" "venv" "python3.11"

# Install TagGUI dependencies inside venv
cd "$TAGGUI_DIR"
source "$TAGGUI_DIR/venv/bin/activate"
pip install -r requirements.txt
deactivate
echo "TagGUI installation complete."

# --- Final Message ---
echo "Installation finished!"
echo "To run One-Trainer: source $ONE_TRAINER_DIR/venv/bin/activate && python $ONE_TRAINER_DIR/start-ui.sh"
echo "To run TagGUI: source $TAGGUI_DIR/venv/bin/activate && python $TAGGUI_DIR/run_gui.py"
