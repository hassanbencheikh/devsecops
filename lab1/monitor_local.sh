#!/bin/bash

# Define container and image names
IMAGE_NAME="arithmetic-api"
CONTAINER_NAME="arithmetic-api-container"
FILE_TO_WATCH="app.py"

echo "Starting initial build and run..."

# Stop and remove existing container if it exists
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# Build and run the container
docker build -t $IMAGE_NAME .
docker run -d --name $CONTAINER_NAME -p 5000:5000 $IMAGE_NAME

echo "Monitoring $FILE_TO_WATCH for changes..."

# Use inotifywait to monitor the file for modifications
while inotifywait -e modify $FILE_TO_WATCH; do
    echo "Change detected in $FILE_TO_WATCH. Rebuilding and redeploying..."

    # Stop and remove the old container
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME

    # Rebuild the Docker image
    docker build -t $IMAGE_NAME .

    # Run the new container
    docker run -d --name $CONTAINER_NAME -p 5000:5000 $IMAGE_NAME

    echo "Container updated successfully. Monitoring again..."
done

