#!/bin/bash

# --------------------------
# Usage:
# ./docker_push.sh <dockerhub_username> <repository_name> <tag> [dockerfile_path]
# Example:
# ./docker_push.sh myuser myapp v1.0 .
# --------------------------

set -e  # exit on error

# Read arguments
DOCKER_USERNAME="ethanmcdonnell"
DOCKER_REPO="$2"
IMAGE_TAG="latest"       # default to "latest" if not provided
DOCKERFILE_PATH="$1"      # default to current directory

if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_REPO" ] || [ -z "$DOCKERFILE_PATH" ]; then
    echo "Usage: $0 <dockerhub_username> <repository_name> <tag> [dockerfile_path]"
    exit 1
fi

# Full image name (Docker Hub)
FULL_IMAGE_NAME="$DOCKER_USERNAME/$DOCKER_REPO:$IMAGE_TAG"

# Login to Docker Hub
echo "Logging in to Docker Hub..."
docker login || { echo "Docker login failed"; exit 1; }

# Build Docker image directly with the full image name
echo "Building Docker image: $FULL_IMAGE_NAME ..."
docker build --platform linux/amd64 -t "$FULL_IMAGE_NAME" -f "$DOCKERFILE_PATH/Dockerfile" "$DOCKERFILE_PATH"

# Push the image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
docker push "$FULL_IMAGE_NAME"

echo "Removing local Docker image: $FULL_IMAGE_NAME ..."
docker rmi "$FULL_IMAGE_NAME"

echo "Docker image $FULL_IMAGE_NAME pushed and local copy removed successfully!"
