#!/bin/bash

set -euo pipefail

# Build and push single app image to private registry.
# Usage: REGISTRY_USERNAME=admin REGISTRY_PASSWORD=****** ./build-and-push.sh [tag] [registry-host] [registry-repository]
# Example: REGISTRY_USERNAME=admin REGISTRY_PASSWORD=****** ./build-and-push.sh v1.0.0

TAG="${1:-latest}"
REGISTRY_HOST="${2:-${REGISTRY_HOST:-registry.zata.cafe}}"
REGISTRY_REPOSITORY="${3:-${REGISTRY_REPOSITORY:-admin/transfileserver-app}}"
REGISTRY_USERNAME="${REGISTRY_USERNAME:-}"
REGISTRY_PASSWORD="${REGISTRY_PASSWORD:-}"

if [ -z "$REGISTRY_USERNAME" ] || [ -z "$REGISTRY_PASSWORD" ]; then
    echo "Error: REGISTRY_USERNAME and REGISTRY_PASSWORD must be set"
    echo "Example:"
    echo "  REGISTRY_USERNAME=admin REGISTRY_PASSWORD=****** $0 latest"
    exit 1
fi

IMAGE="$REGISTRY_HOST/$REGISTRY_REPOSITORY"

echo "Logging in to registry: $REGISTRY_HOST"
echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY_HOST" -u "$REGISTRY_USERNAME" --password-stdin

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
echo "  REGISTRY_HOST=$REGISTRY_HOST REGISTRY_REPOSITORY=$REGISTRY_REPOSITORY APP_IMAGE_TAG=$TAG docker compose -f docker-compose.prod.yml up -d --pull always"
