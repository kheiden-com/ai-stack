# Stop script on any error
$ErrorActionPreference = "Stop"

# --- Functions for logging ---
function Log-Info {
    param ([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Log-Warn {
    param ([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Log-Error {
    param ([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    # Pause for user to see the error before exiting
    if ($Host.UI.RawUI) {
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    }
    exit 1
}

# --- 1. Prerequisite Checks ---
Log-Info "Checking for prerequisites..."

# Check for Docker
try {
    Get-Command docker -ErrorAction Stop | Out-Null
} catch {
    Log-Error "Docker could not be found. Please install Docker Desktop for Windows before running this script. Press any key to exit."
}

# Check for Docker Compose (v1 or v2)
$composeCmd = $null
if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
    $composeCmd = "docker-compose"
} elseif ((Get-Command docker -ErrorAction SilentlyContinue) -and (docker compose version -ErrorAction SilentlyContinue)) {
    $composeCmd = "docker compose"
} else {
    Log-Error "Docker Compose could not be found. Please ensure Docker Compose is enabled in Docker Desktop. Press any key to exit."
}
Log-Info "Using '$composeCmd' for Docker Compose commands."

Log-Info "Prerequisites are satisfied."

# --- 2. Environment File Setup ---
Log-Info "Setting up environment file..."
$envFile = ".env"
if (-not (Test-Path -Path $envFile)) {
    Log-Info "No .env file found. Copying from .env.template..."
    Copy-Item -Path ".env.template" -Destination $envFile
    Log-Warn "A new .env file has been created. Please review it and customize if necessary before running the stack again."
} else {
    Log-Info ".env file already exists. Skipping creation."
}

# --- 3. GPU Support Check ---
Log-Info "Checking for Nvidia GPU support..."
$composeFile = "docker-compose-cpu.yaml" # Default to CPU
try {
    # Attempt to run a container that requires a GPU.
    # We suppress command output and check the exit code to determine success.
    # This try/catch block will handle terminating errors from docker.
    docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Log-Info "Nvidia GPU support detected. Using GPU configuration."
        $composeFile = "docker-compose-gpu.yaml"
    } else {
        # If the command returns a non-zero exit code without a terminating error,
        # we manually trigger the catch block to ensure we fall back to CPU.
        throw "GPU check command failed."
    }
} catch {
    Log-Warn "Nvidia GPU support not detected or Docker is not configured correctly for GPU passthrough."
    Log-Warn "Falling back to CPU-only configuration. Note: Performance for LLM tasks will be significantly reduced."
}

# --- 4. Build and Launch the Stack ---
Log-Info "Building and launching the Docker stack using '$composeFile'..."
Log-Info "This might take a while, especially on the first run, as images need to be downloaded and built."

# The compose command needs to be invoked carefully if it contains spaces
try {
    Invoke-Expression "$composeCmd -f $composeFile up --build -d"
} catch {
    Log-Error "Failed to start the Docker stack. Please check the output above for errors. Press any key to exit."
}

Log-Info "Docker stack has been started successfully!"
Log-Info "It may take a few minutes for all services to become fully available."
Log-Info "You can check the status of the services by running: '$composeCmd -f $composeFile ps'"
Log-Info "To view logs, run: '$composeCmd -f $composeFile logs -f'"