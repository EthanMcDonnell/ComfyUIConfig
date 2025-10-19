#!/bin/bash
# Expose port 5000 for gui access

# Exit on errors
set -e

# Define directories
INSTALL_DIR="$HOME/runpod_tools"
ONE_TRAINER_DIR="$INSTALL_DIR/one-trainer"
TAGGUI_DIR="$INSTALL_DIR/taggui"

echo "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# --- Install One-Trainer ---
echo "Cloning one-trainer..."
git clone https://github.com/ONE-Artist/one-trainer.git "$ONE_TRAINER_DIR"

echo "Installing one-trainer dependencies..."
cd "$ONE_TRAINER_DIR"
pip install -r requirements.txt

echo "One-trainer installation complete."

# --- Install TagGUI ---
echo "Cloning TagGUI..."
git clone https://github.com/jhc13/taggui.git "$TAGGUI_DIR"

echo "Installing TagGUI dependencies..."
cd "$TAGGUI_DIR"
pip install -r requirements.txt

echo "TagGUI installation complete."

# --- Final Message ---
echo "Installation finished!"
echo "To run One-Trainer: python $ONE_TRAINER_DIR/main.py"
echo "To run TagGUI: python $TAGGUI_DIR/taggui.py"
