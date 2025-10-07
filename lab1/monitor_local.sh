#!/bin/bash

# Your GitHub repository local path
REPO_DIR="/home/kali/Desktop/Platforms/SelfLearn/DevSecOps/Lab1"

# Docker container and image names
IMAGE_NAME="arithmetic-api"
CONTAINER_NAME="arithmetic-api-container"

# Move to the repository directory
cd "$REPO_DIR" || { echo "Repo directory $REPO_DIR not found."; exit 1; }

echo "Starting initial build and deployment..."

# Stop and remove existing container if running
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# Initial build and run
docker build -t $IMAGE_NAME .
docker run -d --name $CONTAINER_NAME -p 5000:5000 $IMAGE_NAME

# Get the current commit hash
CURRENT_HASH=$(git rev-parse HEAD)

echo "Monitoring GitHub repository (https://github.com/hassanbencheikh/devsecops.git) for new commits..."

while true; do
    git fetch origin

    REMOTE_HASH=$(git rev-parse origin/main)

    if [ "$CURRENT_HASH" != "$REMOTE_HASH" ]; then
        echo "New commit detected ($REMOTE_HASH). Pulling changes and deploying..."
        
        git pull origin main
        
        CURRENT_HASH=$REMOTE_HASH
        
        # Stop and remove old container
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME

        # Build and run updated container
        docker build -t $IMAGE_NAME .
        docker run -d --name $CONTAINER_NAME -p 5000:5000 $IMAGE_NAME
        
        echo "Deployment updated successfully."
    else
        echo "No new commits detected. Checking again in 60 seconds..."
    fi

    sleep 60
done
