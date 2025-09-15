#!/bin/bash

# A script to copy data from one Docker image to another, creating a new image.
# Usage: ./copy_image_data.sh <source_image> <path_in_source> <dest_image> <path_in_dest> <new_image_tag>

set -e

# --- Argument Parsing ---
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <source_image> <path_in_source> <dest_image> <path_in_dest> <new_image_tag>"
    echo "Example: $0 my-ollama:latest /root/.ollama/models ai-stack-ollama:latest /root/.ollama/models ai-stack-ollama:with-models"
    exit 1
fi

SOURCE_IMAGE=$1
PATH_IN_SOURCE=$2
DEST_IMAGE=$3
PATH_IN_DEST=$4
NEW_IMAGE_TAG=$5

echo "--- Starting Image Copy ---"
echo "Source Image: $SOURCE_IMAGE"
echo "Source Path:  $PATH_IN_SOURCE"
echo "Dest. Image:  $DEST_IMAGE"
echo "Dest. Path:   $PATH_IN_DEST"
echo "New Tag:      $NEW_IMAGE_TAG"
echo "--------------------------"

# --- Main Logic ---

# Create a temporary directory on the host to act as a staging area
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Ensure cleanup happens on script exit
trap 'echo "Cleaning up temporary directory..."; rm -rf "$TEMP_DIR"' EXIT

# Start a temporary container from the source image
echo "Starting source container from $SOURCE_IMAGE..."
SOURCE_CONTAINER_ID=$(docker run -d $SOURCE_IMAGE tail -f /dev/null)
trap 'echo "Cleaning up source container..."; docker stop $SOURCE_CONTAINER_ID > /dev/null; docker rm $SOURCE_CONTAINER_ID > /dev/null; rm -rf "$TEMP_DIR"' EXIT

# Copy the data from the source container to the host's temporary directory
echo "Copying data from $SOURCE_CONTAINER_ID:$PATH_IN_SOURCE to $TEMP_DIR..."
docker cp "$SOURCE_CONTAINER_ID:$PATH_IN_SOURCE" "$TEMP_DIR/data"

# Stop the source container
echo "Stopping source container..."
docker stop $SOURCE_CONTAINER_ID > /dev/null
docker rm $SOURCE_CONTAINER_ID > /dev/null
trap 'rm -rf "$TEMP_DIR"' EXIT # Update trap, source container is gone

# Start a temporary container from the destination image
echo "Starting destination container from $DEST_IMAGE..."
DEST_CONTAINER_ID=$(docker run -d $DEST_IMAGE tail -f /dev/null)
trap 'echo "Cleaning up destination container..."; docker stop $DEST_CONTAINER_ID > /dev/null; docker rm $DEST_CONTAINER_ID > /dev/null; rm -rf "$TEMP_DIR"' EXIT

# Copy the staged data from the host to the destination container
echo "Copying data from $TEMP_DIR/data to $DEST_CONTAINER_ID:$PATH_IN_DEST..."
docker cp "$TEMP_DIR/data" "$DEST_CONTAINER_ID:$PATH_IN_DEST"

# Commit the destination container as a new image
echo "Committing changes to new image: $NEW_IMAGE_TAG..."
docker commit $DEST_CONTAINER_ID $NEW_IMAGE_TAG

# Stop the destination container
echo "Stopping destination container..."
docker stop $DEST_CONTAINER_ID > /dev/null
docker rm $DEST_CONTAINER_ID > /dev/null
trap 'rm -rf "$TEMP_DIR"' EXIT # Update trap, dest container is gone

echo "--- Image Copy Complete ---"
echo "New image created: $NEW_IMAGE_TAG"
