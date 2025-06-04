#!/bin/bash

# Set the base directory to search for Git repositories
BASE_DIR="/home/james"

# Function to check if a directory is a git repository
is_git_repo() {
    [ -d "$1/.git" ]
}

# Function to sync a git repository
sync_repo() {
    local repo_path="$1"
    echo "📂 Syncing repository: $repo_path"
    
    # Change to the repository directory
    cd "$repo_path" || return 1
    
    # Get the current branch name
    local branch=$(git branch --show-current)
    
    # Configure git pull to use rebase
    git config pull.rebase true
    
    # Pull the latest changes
    echo "📥 Pulling latest changes from branch: $branch"
    if git pull; then
        echo "✅ Successfully synced $repo_path"
        return 0
    else
        echo "❌ Failed to sync $repo_path"
        return 1
    fi
}

# Find all git repositories and sync them
echo "🔍 Searching for Git repositories in $BASE_DIR..."
find "$BASE_DIR" -type d -name ".git" -prune | while read -r git_dir; do
    # Get the parent directory of .git
    repo_path=$(dirname "$git_dir")
    
    # Skip if it's not a valid git repository
    if ! is_git_repo "$repo_path"; then
        continue
    fi
    
    # Sync the repository
    sync_repo "$repo_path"
    echo "----------------------------------------"
done

echo "✨ Git sync completed!"