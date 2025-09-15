#!/bin/bash
# WARNING: This code was AI generated and has not been tested. Use at your own risk.
# Pull Requests are welcome!

set -e # Exit immediately if a command exits with a non-zero status.

# --- Functions for logging ---
log() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

warn() {
    echo -e "\033[0;33m[WARN]\033[0m $1"
}

error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
    exit 1
}

# --- 1. Prerequisite Checks ---
log "Checking for prerequisites..."

# Check for Docker
if ! command -v docker &> /dev/null; then
    error "Docker could not be found. Please install Docker before running this script."
fi

# Check for Docker Compose (v1 or v2)
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    error "Docker Compose could not be found. Please ensure Docker Compose (either as 'docker-compose' or 'docker compose') is installed."
fi

# Determine which compose command to use
COMPOSE_CMD="docker-compose"
if ! command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker compose"
fi
log "Using '$COMPOSE_CMD' for Docker Compose commands."

log "Prerequisites are satisfied."

# --- 2. Environment File Setup ---
log "Setting up environment file..."
if [ ! -f .env ]; then
    log "No .env file found. Copying from .env.template..."
    cp .env.template .env
    warn "A new .env file has been created. Please review it and customize if necessary before running the stack again."
else
    log ".env file already exists. Skipping creation."
fi

# --- 3. GPU Support Check ---
log "Checking for Nvidia GPU support..."
COMPOSE_FILE="docker-compose-cpu.yaml" # Default to CPU

# Attempt to run nvidia-smi in a container. If it succeeds, a GPU is available.
# The 'if' statement handles the command's exit code without exiting the script.
if docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi &> /dev/null; then
    log "Nvidia GPU support detected. Using GPU configuration."
    COMPOSE_FILE="docker-compose-gpu.yaml"
else
    warn "Nvidia GPU support not detected or Docker is not configured correctly for GPU passthrough."
    warn "Falling back to CPU-only configuration. Note: Performance for LLM tasks will be significantly reduced."
fi

# --- 4. Build and Launch the Stack ---
log "Building and launching the Docker stack using '$COMPOSE_FILE'..."
log "This might take a while, especially on the first run, as images need to be downloaded and built."

# Split the compose command to handle the space in "docker compose"
CMD_PARTS=($COMPOSE_CMD)
"${CMD_PARTS[@]}" -f "$COMPOSE_FILE" up --build -d

log "Docker stack has been started successfully!"
log "It may take a few minutes for all services to become fully available."
log "You can check the status of the services by running: '$COMPOSE_CMD -f $COMPOSE_FILE ps'"
log "To view logs, run: '$COMPOSE_CMD -f $COMPOSE_FILE logs -f'"