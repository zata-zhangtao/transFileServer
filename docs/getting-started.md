# Getting Started

This guide will help you set up and run the File Transfer Server on your local machine or in production.

## Prerequisites

### System Requirements
- Python 3.8 or higher
- Node.js 14 or higher (for frontend development)
- 4GB RAM minimum
- 10GB free disk space

### Tools
- Git (for cloning the repository)
- Text editor or IDE
- Terminal/Command prompt

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd transFileServer
```

### 2. Backend Setup

#### Option A: Using pip (Recommended)
```bash
# Install dependencies
pip install -r requirements.txt

# Verify installation
python -c "import fastapi; print('FastAPI installed successfully')"
```

#### Option B: Using pip with editable install
```bash
# Install in development mode
pip install -e .
```

### 3. Frontend Setup

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Verify installation
npm list react
```

## Running the Application

### Development Mode

#### Start the Backend Server
```bash
# From the project root directory
python main.py
```

The backend will start on `http://localhost:8000`

#### Start the Frontend Server
```bash
# In a new terminal, navigate to frontend directory
cd frontend

# Start the development server
npm start
```

The frontend will start on `http://localhost:3000`

### Production Mode

#### Using Docker (Recommended)
```bash
# Build and run both services
docker-compose up -d

# Or for production configuration
docker-compose -f docker-compose.prod.yml up -d
```

#### Manual Production Setup
```bash
# Backend
uvicorn main:app --host 0.0.0.0 --port 8000

# Frontend (build and serve)
cd frontend
npm run build
# Serve the build directory with your preferred web server
```

## Basic Usage

### Using the Web Interface

1. Open your browser and go to `http://localhost:3000`
2. You'll see the File Transfer Server interface with two main sections:

#### File Transfer Features
- Upload files by dragging and dropping
- Upload text content
- View uploaded files
- Download files by ID
- Delete files

### Using the API

#### Upload a File
```bash
curl -X POST "http://localhost:8000/upload" \
  -F "file=@/path/to/your/file.txt"
```

#### Upload Text Content
```bash
curl -X POST "http://localhost:8000/upload" \
  -F "text=Hello, World!"
```

#### List Files
```bash
curl -X GET "http://localhost:8000/files"
```

#### Download a File
```bash
curl -X GET "http://localhost:8000/download/YOUR_FILE_ID" \
  -o downloaded_file.txt
```

#### Delete a File
```bash
curl -X DELETE "http://localhost:8000/delete/YOUR_FILE_ID"
```


## Configuration

### Environment Variables

#### Backend
- `PORT`: Server port (default: 8000)
- `UPLOAD_DIR`: Directory for file storage (default: uploads/)

#### Frontend
- `REACT_APP_API_URL`: Backend API URL (default: http://localhost:8000)

### Setting Environment Variables

#### Development
Create a `.env` file in the project root:
```env
PORT=8000
REACT_APP_API_URL=http://localhost:8000
```

#### Production
```bash
export PORT=8000
export REACT_APP_API_URL=https://your-domain.com
```

## File Storage

### Storage Location
Files are stored in the `uploads/` directory with the following structure:
```
uploads/
├── 550e8400-e29b-41d4-a716-446655440000_document.pdf
├── 6ba7b810-9dad-11d1-80b4-00c04fd430c8_image.png
└── 6ba7b811-9dad-11d1-80b4-00c04fd430c8.txt
```

### File Naming Convention
- Regular files: `{uuid}_{original_filename}`
- Text files: `{uuid}.txt`

### Storage Considerations
- Files are stored permanently until manually deleted
- No automatic cleanup or expiration
- Consider implementing file rotation for production use

## Security Considerations

### Development
- CORS is enabled for all origins
- No authentication required
- All endpoints are publicly accessible

### Production Recommendations
1. **Restrict CORS origins**:
   ```python
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["https://your-domain.com"],  # Restrict to specific domains
       allow_credentials=True,
       allow_methods=["GET", "POST", "DELETE"],
       allow_headers=["*"],
   )
   ```

2. **Add authentication**:
   - Implement API keys or JWT tokens
   - Add user authorization for file operations

3. **File type restrictions**:
   - Validate file types before upload
   - Implement file size limits

4. **Rate limiting**:
   - Add rate limiting to prevent abuse
   - Implement request quotas

## Troubleshooting

### Common Issues

#### "Module not found" errors
```bash
# Make sure you're in the right directory and dependencies are installed
pip install -r requirements.txt
```

#### Port already in use
```bash
# Kill processes using the port
lsof -ti:8000 | xargs kill -9
```

#### Frontend can't connect to backend
- Check that the backend is running on the correct port
- Verify `REACT_APP_API_URL` is set correctly
- Check for CORS issues in browser developer tools

#### File upload fails
- Check file permissions in the uploads directory
- Verify disk space availability
- Check server logs for detailed error messages


### Getting Help

1. Check the server logs for detailed error messages
2. Use browser developer tools to inspect network requests
3. Verify all services are running on the correct ports
4. Check the [API documentation](api/overview.md) for correct request formats

## Next Steps

### For Developers
- Explore the [API Reference](api/overview.md) for detailed endpoint documentation
- Check the [Deployment Guide](deployment.md) for production deployment
- Consider implementing additional features like user authentication

### For Users
- Start uploading and sharing files
- Use the web interface for basic operations
- Integrate with your applications using the REST API

### Advanced Usage
- Set up automated backups
- Implement file scanning and security checks
- Add monitoring and logging
- Scale with load balancers and multiple instances