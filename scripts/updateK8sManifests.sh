#!/bin/bash

set -xe  # Enable debugging and exit on errors

# Validate input arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <deployment> <repo> <tag>"
    exit 1
fi

# Input arguments
DEPLOYMENT=$1
IMAGE_REPO=$2
IMAGE_TAG=$3

# Validate environment variables
if [ -z "$GIT_USERNAME" ] || [ -z "$GIT_TOKEN" ] || [ -z "$GIT_REPO_URL" ]; then
    echo "Error: Missing required environment variables (GIT_USERNAME, GIT_TOKEN, GIT_REPO_URL)"
    exit 1
fi

REPO_URL="https://${GIT_USERNAME}:${GIT_TOKEN}@${GIT_REPO_URL}"

# Check if yq is installed
if ! command -v yq &>/dev/null; then
    echo "Error: yq is not installed. Please install it and try again."
    exit 1
fi

# Create a unique temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT
echo "Using temporary directory: $TEMP_DIR"

# Clone the git repository
echo "Cloning repository: $REPO_URL"
if ! git clone "$REPO_URL" "$TEMP_DIR"; then
    echo "Error: Failed to clone repository"
    exit 1
fi

# Navigate into the repository
cd "$TEMP_DIR"

# Validate Kubernetes manifest file
MANIFEST_PATH="k8s-specifications/${DEPLOYMENT}-deployment.yaml"
if [ ! -f "$MANIFEST_PATH" ]; then
    echo "Error: Manifest file not found: $MANIFEST_PATH"
    exit 1
fi

# Update the Kubernetes manifest
echo "Updating Kubernetes manifest: $MANIFEST_PATH"
yq eval ".spec.template.spec.containers[0].image = \"${IMAGE_REPO}:${IMAGE_TAG}\"" -i "$MANIFEST_PATH"

# Add and commit changes
echo "Staging changes"
git add .
echo "Committing changes"
git commit -m "Update Kubernetes manifest for ${DEPLOYMENT} to ${IMAGE_REPO}:${IMAGE_TAG}"

# Push changes
echo "Pushing changes to repository"
if ! git push; then
    echo "Error: Failed to push changes"
    exit 1
fi

echo "Script completed successfully"

