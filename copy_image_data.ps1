<#
.SYNOPSIS
    Copies a directory from a source Docker image to a destination Docker image, creating a new image.

.DESCRIPTION
    This script facilitates the transfer of data between two Docker images. It works by:
    1. Creating a temporary container from the source image.
    2. Copying a specified directory to a temporary location on the host.
    3. Creating a temporary container from the destination image.
    4. Copying the data from the host into the destination container.
    5. Committing the modified destination container to a new image tag.
    It ensures cleanup of all temporary containers and directories.

.PARAMETER SourceImage
    The name and tag of the source Docker image (e.g., 'my-ollama:latest').

.PARAMETER PathInSource
    The absolute path to the directory to copy from within the source image (e.g., '/root/.ollama/models').

.PARAMETER DestImage
    The name and tag of the destination Docker image (e.g., 'ai-stack-ollama:latest').

.PARAMETER PathInDest
    The absolute path where the data should be copied to within the destination image (e.g., '/root/.ollama/models').

.PARAMETER NewImageTag
    The name and tag for the newly created Docker image (e.g., 'ai-stack-ollama:with-models').

.EXAMPLE
    PS> ./copy_image_data.ps1 -SourceImage my-ollama:latest -PathInSource /root/.ollama/models -DestImage ai-stack-ollama:latest -PathInDest /root/.ollama/models -NewImageTag ollama:with-my-models
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SourceImage,

    [Parameter(Mandatory=$true)]
    [string]$PathInSource,

    [Parameter(Mandatory=$true)]
    [string]$DestImage,

    [Parameter(Mandatory=$true)]
    [string]$PathInDest,

    [Parameter(Mandatory=$true)]
    [string]$NewImageTag
)

# Stop script on any error
$ErrorActionPreference = "Stop"

# --- Resource Tracking ---
$sourceContainerId = $null
$destContainerId = $null
# Create a temporary directory on the host to act as a staging area
$tempDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tempDir | Out-Null


try {
    Write-Host "--- Starting Image Copy ---"
    Write-Host "Source Image: $SourceImage"
    Write-Host "Source Path:  $PathInSource"
    Write-Host "Dest. Image:  $DestImage"
    Write-Host "Dest. Path:   $PathInDest"
    Write-Host "New Tag:      $NewImageTag"
    Write-Host "Temp Dir:     $tempDir"
    Write-Host "--------------------------"

    # --- Main Logic ---

    # 1. Start a temporary container from the source image
    Write-Host "Starting source container from $SourceImage..."
    $sourceContainerId = docker run -d $SourceImage tail -f /dev/null
    Write-Host "Source container created: $sourceContainerId"

    # 2. Copy data from source container to host's temp directory
    $stagePath = Join-Path $tempDir "data"
    Write-Host "Copying data from '$sourceContainerId`:$PathInSource' to '$stagePath'..."
    docker cp "$sourceContainerId`:$PathInSource" $stagePath

    # 3. Stop and remove the source container
    Write-Host "Stopping source container..."
    docker stop $sourceContainerId | Out-Null
    docker rm $sourceContainerId | Out-Null
    $sourceContainerId = $null # Mark as cleaned up

    # 4. Start a temporary container from the destination image
    Write-Host "Starting destination container from $DestImage..."
    $destContainerId = docker run -d $DestImage tail -f /dev/null
    Write-Host "Destination container created: $destContainerId"

    # 5. Copy staged data from host to the destination container
    Write-Host "Copying data from '$stagePath' to '$destContainerId`:$PathInDest'..."
    docker cp $stagePath "$destContainerId`:$PathInDest"

    # 6. Commit the destination container as a new image
    Write-Host "Committing changes to new image: $NewImageTag..."
    docker commit $destContainerId $NewImageTag | Out-Null

    Write-Host "--- Image Copy Complete ---" -ForegroundColor Green
    Write-Host "New image created successfully: $NewImageTag"

}
finally {
    # --- Cleanup ---
    Write-Host "--- Starting Cleanup ---"

    if ($sourceContainerId) {
        Write-Host "Cleaning up orphaned source container: $sourceContainerId"
        docker stop $sourceContainerId -ErrorAction SilentlyContinue | Out-Null
        docker rm $sourceContainerId -ErrorAction SilentlyContinue | Out-Null
    }

    if ($destContainerId) {
        Write-Host "Cleaning up destination container: $destContainerId"
        docker stop $destContainerId -ErrorAction SilentlyContinue | Out-Null
        docker rm $destContainerId -ErrorAction SilentlyContinue | Out-Null
    }

    if (Test-Path -Path $tempDir) {
        Write-Host "Cleaning up temporary directory: $tempDir"
        Remove-Item -Recurse -Force -Path $tempDir -ErrorAction SilentlyContinue
    }
    
    Write-Host "--- Cleanup Complete ---"
}
