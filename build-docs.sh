#!/bin/bash

# MkDocs Build Script for File Transfer Server Documentation
# This script provides common MkDocs operations for documentation management

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$PROJECT_DIR/docs"
SITE_DIR="$PROJECT_DIR/site"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if mkdocs is installed
check_mkdocs() {
    if ! command -v mkdocs &> /dev/null; then
        print_error "MkDocs is not installed. Please install it with: pip install mkdocs mkdocs-material"
        exit 1
    fi
    print_status "MkDocs is installed: $(mkdocs --version)"
}

# Install MkDocs and dependencies
install_deps() {
    print_header "Installing MkDocs Dependencies"
    pip install mkdocs mkdocs-material
    print_status "Dependencies installed successfully"
}

# Build the documentation
build_docs() {
    print_header "Building Documentation"
    cd "$PROJECT_DIR"
    
    # Clean previous build
    if [ -d "$SITE_DIR" ]; then
        print_status "Cleaning previous build..."
        rm -rf "$SITE_DIR"
    fi
    
    # Build the site
    print_status "Building MkDocs site..."
    mkdocs build --strict
    
    print_status "Documentation built successfully in $SITE_DIR"
}

# Serve the documentation locally
serve_docs() {
    print_header "Serving Documentation Locally"
    cd "$PROJECT_DIR"
    
    print_status "Starting MkDocs development server..."
    print_status "Documentation will be available at: http://127.0.0.1:8001"
    print_status "Press Ctrl+C to stop the server"
    
    # Use port 8001 to avoid conflict with the API server on 8000
    mkdocs serve --dev-addr 127.0.0.1:8001
}

# Deploy to GitHub Pages
deploy_docs() {
    print_header "Deploying Documentation to GitHub Pages"
    cd "$PROJECT_DIR"
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        print_error "This is not a git repository. Cannot deploy to GitHub Pages."
        exit 1
    fi
    
    # Check if there are uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "There are uncommitted changes. Please commit or stash them before deploying."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Deployment cancelled."
            exit 0
        fi
    fi
    
    print_status "Deploying to GitHub Pages..."
    mkdocs gh-deploy --force
    print_status "Documentation deployed successfully to GitHub Pages"
}

# Validate documentation
validate_docs() {
    print_header "Validating Documentation"
    cd "$PROJECT_DIR"
    
    # Check if all referenced files exist
    print_status "Checking for broken links in navigation..."
    
    # Check if all navigation files exist
    print_status "Checking navigation files..."
    
    # Check key documentation files
    nav_files=(
        "docs/index.md"
        "docs/getting-started.md"
        "docs/api/overview.md"
        "docs/api/upload.md"
        "docs/api/download.md"
        "docs/api/files.md"
        "docs/api/delete.md"
        "docs/deployment.md"
        "docs/examples.md"
    )
    
    missing_files=()
    for file in "${nav_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        print_status "All navigation files exist"
    else
        print_error "Missing navigation files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        exit 1
    fi
    
    # Build in strict mode to catch any issues
    print_status "Building in strict mode to catch warnings..."
    mkdocs build --strict --clean
    
    print_status "Documentation validation completed successfully"
}

# Clean build artifacts
clean_docs() {
    print_header "Cleaning Documentation Build Artifacts"
    
    if [ -d "$SITE_DIR" ]; then
        print_status "Removing build directory: $SITE_DIR"
        rm -rf "$SITE_DIR"
    fi
    
    print_status "Clean completed"
}

# Show help
show_help() {
    echo "MkDocs Build Script for File Transfer Server Documentation"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  install    Install MkDocs and dependencies"
    echo "  build      Build the documentation"
    echo "  serve      Start local development server"
    echo "  deploy     Deploy to GitHub Pages"
    echo "  validate   Validate documentation structure"
    echo "  clean      Clean build artifacts"
    echo "  help       Show this help message"
    echo
    echo "Examples:"
    echo "  $0 install          # Install dependencies"
    echo "  $0 build            # Build documentation"
    echo "  $0 serve            # Start development server"
    echo "  $0 deploy           # Deploy to GitHub Pages"
    echo
    echo "For development workflow:"
    echo "  $0 install && $0 serve"
    echo
    echo "For production deployment:"
    echo "  $0 validate && $0 build && $0 deploy"
}

# Main script logic
main() {
    case "${1:-help}" in
        install)
            install_deps
            ;;
        build)
            check_mkdocs
            build_docs
            ;;
        serve)
            check_mkdocs
            serve_docs
            ;;
        deploy)
            check_mkdocs
            deploy_docs
            ;;
        validate)
            check_mkdocs
            validate_docs
            ;;
        clean)
            clean_docs
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"