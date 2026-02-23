#!/bin/bash

set -euo pipefail

# Multi-platform build and push for single image.
# Usage: REGISTRY_USERNAME=admin REGISTRY_PASSWORD=****** ./build-and-push-multiplatform.sh [tag] [platforms] [registry-host] [registry-repository]
# Example: REGISTRY_USERNAME=admin REGISTRY_PASSWORD=****** ./build-and-push-multiplatform.sh v1.0.0 linux/amd64,linux/arm64

TAG="${1:-latest}"
PLATFORMS="${2:-linux/amd64,linux/arm64}"
REGISTRY_HOST="${3:-${REGISTRY_HOST:-registry.zata.cafe}}"
REGISTRY_REPOSITORY="${4:-${REGISTRY_REPOSITORY:-admin/transfileserver-app}}"
REGISTRY_USERNAME="${REGISTRY_USERNAME:-}"
REGISTRY_PASSWORD="${REGISTRY_PASSWORD:-}"

if [ -z "$REGISTRY_USERNAME" ] || [ -z "$REGISTRY_PASSWORD" ]; then
    echo "Error: REGISTRY_USERNAME and REGISTRY_PASSWORD must be set"
    echo "Example:"
    echo "  REGISTRY_USERNAME=admin REGISTRY_PASSWORD=****** $0 latest linux/amd64,linux/arm64"
    exit 1
fi

IMAGE="$REGISTRY_HOST/$REGISTRY_REPOSITORY"

echo "Logging in to registry: $REGISTRY_HOST"
echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY_HOST" -u "$REGISTRY_USERNAME" --password-stdin

echo "Setting up Docker Buildx..."
docker buildx create --name multiplatform-builder --use --bootstrap 2>/dev/null || docker buildx use multiplatform-builder

echo "Building and pushing:"
echo "  Image: $IMAGE"
echo "  Tag: $TAG"
echo "  Platforms: $PLATFORMS"

docker buildx build \
    --platform "$PLATFORMS" \
    --tag "$IMAGE:$TAG" \
    --tag "$IMAGE:latest" \
    --push \
    .

echo "Done."
echo "Inspect image manifest:"
echo "  docker buildx imagetools inspect $IMAGE:$TAG"
