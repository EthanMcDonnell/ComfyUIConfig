#!/bin/bash
# Runpod VNC + noVNC setup script
# Exits on error
set -e

# --- Variables ---
VNC_PASSWORD="taggui"        # Password for VNC
VNC_DISPLAY=":1"             # Virtual display number
VNC_RESOLUTION="1920x1080"   # Desktop resolution
NOVNC_PORT=5000              # Browser-accessible port
USER_HOME="/root"            # Adjust if using non-root

# --- Install required packages ---
sudo apt-get update
sudo apt-get install -y \
    tigervnc-standalone-server \
    tigervnc-common \
    fluxbox \
    novnc \
    websockify \
    libegl-mesa0 \
    libgles2-mesa-dev \
    libgl1 \
    libglx-mesa0 \
    libgl1-mesa-dri \
    libx11-6 \
    libxrender1 \
    libxext6 \
    libxcb1 \
    mesa-utils \
    x11-xserver-utils

# --- Configure VNC password ---
mkdir -p $USER_HOME/.vnc
echo $VNC_PASSWORD | vncpasswd -f > $USER_HOME/.vnc/passwd
chmod 600 $USER_HOME/.vnc/passwd

# --- Start VNC server ---
echo "Starting VNC server on display $VNC_DISPLAY..."
vncserver $VNC_DISPLAY -geometry $VNC_RESOLUTION -depth 24

# --- Launch noVNC ---
echo "Starting noVNC web client on port $NOVNC_PORT..."
# Link noVNC web directory
NOVNC_DIR=$(dpkg -L novnc | grep /usr/share/novnc$)
websockify --web $NOVNC_DIR $NOVNC_PORT localhost:5901 &

echo "VNC setup complete!"
echo "Access your GUI at: http://<container-ip>:$NOVNC_PORT"
echo "VNC password: $VNC_PASSWORD"
