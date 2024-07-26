#!/bin/bash

# Initialize variables
plnx_ver=""

# Function to show usage
usage() {
    echo "Usage: $0 --plnx_ver version"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --plnx_ver)
            plnx_ver="$2"
            if [[ -z "$plnx_ver" ]]; then
                echo "Error: --plnx_ver requires a value"
                usage
            fi
            shift
            shift
            ;;
        *)
            echo "Error: Unknown argument $1"
            usage
            ;;
    esac
done

# Validate arguments
if [[ -z "$plnx_ver" ]]; then
    echo "Error: --plnx_ver is required"
    usage
fi

# If validation passes, print the variables
echo "Building petalinux build image for version $plnx_ver"

plnx_installers_dir="/petalnux_installers_dir"
plnx_installer_dir="$plnx_installers_dir/$plnx_ver"

# Check if the directory exists
if [[ ! -d "$plnx_installer_dir" ]]; then
    echo "Petalinux directory with installer does not exist on path $plnx_installer_dir"
    exit 1
fi

# Find the installer file
plnx_installer=$(find "$plnx_installer_dir" -type f | head -n 1)

if [[ ! -f "$plnx_installer" ]]; then
    echo "Petalinux installer not found in directory $plnx_installer_dir"
    exit 1
fi

echo "Petalinux installer found: $plnx_installer"

# Set the image name
IMAGE_NAME="build-plnx"

# Extract the filename from the full path
FILENAME=$(basename "$plnx_installer")

# Remove the prefix 'petalinux-v'
TEMP="${FILENAME#petalinux-v}"

# Extract the version number up to the first '-'
PLNX_VER="${TEMP%%-*}"

# Build the Docker image
docker build \
    -f Dockerfile \
    --build-arg="PLNX_VER=$PLNX_VER" \
    --build-arg="INSTALLER_NAME=$FILENAME" \
    -t "$IMAGE_NAME:$PLNX_VER" \
    --build-context "installers=$plnx_installer_dir" .

# Check if the build was successful
if [[ $? -ne 0 ]]; then
    echo "Docker build failed!"
    exit 1
fi

echo "Docker image $IMAGE_NAME:$PLNX_VER built successfully!"