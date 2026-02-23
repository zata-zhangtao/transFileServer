#!/bin/bash

set -euo pipefail

# Multi-platform build and push for single image.
# Usage: ./build-and-push-multiplatform.sh <dockerhub-username> [tag] [platforms]
# Example: ./build-and-push-multiplatform.sh zata v1.0.0 linux/amd64,linux/arm64

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <dockerhub-username> [tag] [platforms]"
    echo "Example: $0 yourname latest linux/amd64,linux/arm64"
    exit 1
fi

USERNAME="$1"
TAG="${2:-latest}"
PLATFORMS="${3:-linux/amd64,linux/arm64}"
IMAGE="$USERNAME/transfileserver-app"

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
