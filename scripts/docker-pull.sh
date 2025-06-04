 #!/bin/bash

# Set the Docker directory path
DOCKER_DIR="/home/james/docker"

# Check if the directory exists
if [ ! -d "$DOCKER_DIR" ]; then
    echo "❌ Error: Docker directory not found at $DOCKER_DIR"
    exit 1
fi

# Change to the Docker directory
cd "$DOCKER_DIR" || exit 1

# Check if it's a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: $DOCKER_DIR is not a git repository"
    exit 1
fi

# Pull the latest changes
echo "📥 Pulling latest changes from git repository..."
git pull

# Check if the pull was successful
if [ $? -eq 0 ]; then
    echo "✅ Successfully pulled latest changes"
else
    echo "❌ Error: Failed to pull latest changes"
    exit 1
fi