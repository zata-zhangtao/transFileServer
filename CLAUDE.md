# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

This is a file transfer server application with a FastAPI backend and React frontend. The architecture follows a simple client-server model:

### Backend (FastAPI - Python)
- **main.py**: Single-file backend with all API endpoints
- **API Endpoints**:
  - `POST /upload` - Upload files or text content
  - `GET /download/{file_id}` - Download files by UUID
  - `GET /files` - List all available files  
  - `DELETE /delete/{file_id}` - Delete files by UUID
- **File Storage**: Files stored in `uploads/` directory with UUID-based naming
- **CORS**: Configured to allow all origins for development

### Frontend (React - TypeScript)
- **src/App.tsx**: Main application component with all functionality
- **Key Features**: File upload, text upload, download by ID, file listing, file deletion
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

# Build and push to Docker Hub
./build-and-push.sh your-username

# Multi-platform build (supports ARM64 Mac building x86 images)
./build-and-push-multiplatform.sh your-username
```

## File Structure Notes

- **uploads/**: Directory where uploaded files are stored (auto-created)
- **frontend/**: Complete React application with its own package.json
- **Docker**: Separate Dockerfiles for backend (root) and frontend (frontend/)
- **Build Scripts**: Shell scripts for Docker image building and pushing

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
- **CORS**: Wide open for development (should be restricted in production)
- **File Discovery**: Uses glob patterns to find files by UUID prefix

## Deployment Notes

### Docker Hub Deployment
- Multi-platform build script supports ARM64 Mac building x86 images
- Frontend image supports runtime environment variable injection
- `REACT_APP_API_URL` is dynamically replaced at container startup
- Use `.env` files for environment variable management in production

### Production Configuration
- Frontend requires browser-accessible API URL (not Docker internal names)
- Backend and frontend have separate Docker images for scalability
- Deployment documentation available in `DEPLOYMENT.md` (Chinese)

## Code Structure Notes

- **Frontend**: Single-component React app with extensive inline documentation
- **Backend**: Single-file FastAPI app with all endpoints in `main.py`
- **No testing framework**: Project uses default React testing setup but no backend tests
- **No linting configuration**: Standard Create React App ESLint setup only