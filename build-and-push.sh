#!/bin/bash

set -euo pipefail

# Build and push single app image to Docker Hub.
# Usage: ./build-and-push.sh <dockerhub-username> [tag]
# Example: ./build-and-push.sh zata v1.0.0

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <dockerhub-username> [tag]"
    echo "Example: $0 yourname v1.0.0"
    exit 1
fi

USERNAME="$1"
TAG="${2:-latest}"
IMAGE="$USERNAME/transfileserver-app"

echo "Building image: $IMAGE:$TAG"
docker build -t "$IMAGE:$TAG" -t "$IMAGE:latest" .

echo "Pushing image: $IMAGE:$TAG"
docker push "$IMAGE:$TAG"

if [ "$TAG" != "latest" ]; then
    echo "Pushing image: $IMAGE:latest"
    docker push "$IMAGE:latest"
fi

echo "Done."
echo "Deploy with:"
echo "  DOCKERHUB_USERNAME=$USERNAME APP_IMAGE_TAG=$TAG docker compose -f docker-compose.prod.yml up -d --pull always"
