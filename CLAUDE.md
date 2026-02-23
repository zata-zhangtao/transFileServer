# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

This is a file transfer server application with a FastAPI backend and React frontend. The architecture follows a simple client-server model:

### Backend (FastAPI - Python)
- **main.py**: Single-file backend with all API endpoints
- **API Endpoints**:
  - `POST /upload` - Upload files or text content (for small files)
  - `POST /upload-chunk` - Upload file chunks for large files
  - `GET /upload-status/{file_id}` - Check chunked upload status
  - `GET /download/{file_id}` - Download files by UUID
  - `GET /files` - List all available files  
  - `DELETE /delete/{file_id}` - Delete files by UUID
- **File Storage**: Files stored in `uploads/` directory with UUID-based naming
- **Chunked Upload**: Large files (>10MB) automatically use chunked upload with 5MB chunks
- **CORS**: Configured to allow all origins for development

### Frontend (React - TypeScript)
- **src/App.tsx**: Main application component with all functionality
- **Key Features**: File upload, text upload, download by ID, file listing, file deletion
- **Large File Support**: Automatic chunked upload for files >10MB with progress tracking
- **Download Progress**: Real-time progress tracking for downloads using XMLHttpRequest
- **API Integration**: Uses `REACT_APP_API_URL` environment variable for backend URL

## Common Development Commands

### Backend Development
```bash
# Install dependencies (legacy method)
pip install -r requirements.txt

# Install dependencies (modern method - uses pyproject.toml)
pip install .

# Run development server
python main.py

# Alternative with uvicorn
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Development
```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Run development server
npm start

# Build for production
npm run build

# Run tests
npm test
```

### Docker Development
```bash
# Development environment (both services)
docker-compose up

# Production environment
docker-compose -f docker-compose.prod.yml up -d

# Build and push to private registry
REGISTRY_USERNAME=admin REGISTRY_PASSWORD=****** ./build-and-push.sh latest

# Multi-platform build (supports ARM64 Mac building x86 images)
REGISTRY_USERNAME=admin REGISTRY_PASSWORD=****** ./build-and-push-multiplatform.sh latest linux/amd64,linux/arm64

# Remote deployment to test servers
./deploy-remote-test.sh <server-ip> <ssh-user> <registry-namespace> [ssh-port] [backend-port] [frontend-port] [registry-host]
```

## File Structure Notes

- **uploads/**: Directory where uploaded files are stored (auto-created)
- **frontend/**: Complete React application with its own package.json
- **Docker**: Separate Dockerfiles for backend (root) and frontend (frontend/)
- **Build Scripts**: Shell scripts for Docker image building and pushing
- **Deployment Scripts**: 
  - `deploy-remote-test.sh`: Automated remote deployment with SSH
  - `build-and-push-multiplatform.sh`: Multi-platform Docker builds

## Environment Variables

### Backend
- Runs on port 8000 by default
- No special environment variables required

### Frontend
- `REACT_APP_API_URL`: Backend API URL (defaults to http://localhost:8000)
- Development server runs on port 3000
- Production build serves on port 80 (nginx)
- **Important**: Frontend runs in browser, so API URL must be externally accessible
- Cannot use Docker internal service names (like `http://backend:8000`)
- For production deployment, use domain/IP accessible from user's browser

## Key Implementation Details

- **File ID System**: Uses UUID4 for unique file identification
- **File Naming**: Backend stores files as `{uuid}_{original_filename}` 
- **Text Uploads**: Stored as `{uuid}.txt` files
- **Large File Handling**: 
  - Files >10MB use chunked upload (5MB chunks)
  - Temporary chunks stored in `chunks/` directory during upload
  - Chunks automatically merged when upload completes
- **Download Enhancement**: 
  - Includes `Content-Length` header for progress tracking
  - Includes `Accept-Ranges: bytes` header for range request support
  - Frontend uses XMLHttpRequest for real-time progress updates
- **CORS**: Wide open for development (should be restricted in production)
- **File Discovery**: Uses glob patterns to find files by UUID prefix

## Deployment Notes

### Private Registry Deployment
- Multi-platform build script supports ARM64 Mac building x86 images
- Production uses single image: `transfileserver-app`
- Default image path: `registry.zata.cafe/admin/transfileserver-app`
- Use `.env` files for environment variable management in production
- **Remote Deployment**: Automated SSH-based deployment script for test environments

### Production Configuration
- Compose variables: `REGISTRY_HOST`, `REGISTRY_NAMESPACE`, `APP_IMAGE_TAG`, `APP_PORT`
- Deployment documentation available in `docs/deployment.md`

## Documentation

### MkDocs API Documentation
```bash
# Install documentation dependencies
pip install -r docs-requirements.txt

# Build documentation
./build-docs.sh build

# Serve documentation locally (http://127.0.0.1:8001)
./build-docs.sh serve

# Deploy to GitHub Pages
./build-docs.sh deploy

# Validate documentation structure
./build-docs.sh validate

# Clean build artifacts
./build-docs.sh clean
```

### Documentation Structure
- **docs/**: MkDocs source files
- **mkdocs.yml**: MkDocs configuration with Material theme
- **build-docs.sh**: Documentation build and deployment script
- **docs-requirements.txt**: Documentation dependencies
- **site/**: Generated documentation (auto-created)

## Code Structure Notes

- **Frontend**: Single-component React app with extensive inline documentation
- **Backend**: Single-file FastAPI app with all endpoints in `main.py`
- **No testing framework**: Project uses default React testing setup but no backend tests
- **No linting configuration**: Standard Create React App ESLint setup only

## Recent Enhancements

### Download Progress Tracking
- Backend now includes `Content-Length` and `Accept-Ranges` headers
- Frontend implements XMLHttpRequest-based downloads with progress callbacks
- Real-time progress bars with visual feedback during downloads
- Proper error handling and status management for download operations

### Enhanced Deployment
- Added automated remote deployment script (`deploy-remote-test.sh`)
- Supports SSH-based deployment to remote test servers
- Configurable ports and automatic cleanup of old versions
- Multi-platform Docker build support for ARM64 and x86_64 architectures

### Documentation Updates
- Complete API documentation with progress tracking examples
- Enhanced deployment guide with automated deployment options
- Comprehensive examples for frontend integration and progress UI
