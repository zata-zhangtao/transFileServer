# Deployment Guide

This guide covers various deployment options for the File Transfer Server in production environments.

## Docker Hub Deployment (Recommended)

### Prerequisites
- Docker installed on your server
- Docker Hub account
- Basic understanding of Docker and docker-compose

### 1. Prepare Docker Hub Account

1. Register a [Docker Hub](https://hub.docker.com/) account
2. Login to Docker Hub locally:
   ```bash
   docker login
   ```

### 2. Build and Push Images

#### Option A: Multi-platform Build (Recommended)

Supports building x86 images from ARM64 Macs:

1. Make the script executable:
   ```bash
   chmod +x build-and-push-multiplatform.sh
   ```

2. Build and push multi-platform images:
   ```bash
   # Build for both ARM64 and x86_64
   ./build-and-push-multiplatform.sh your-username
   
   # Or build only x86_64 (suitable for x86 servers)
   ./build-and-push-multiplatform.sh your-username latest linux/amd64
   
   # Or specify custom version
   ./build-and-push-multiplatform.sh your-username v1.0 linux/amd64,linux/arm64
   ```

3. Verify multi-platform support:
   ```bash
   docker buildx imagetools inspect your-username/transfileserver-backend:latest
   ```

#### Option B: Single Platform Build

1. Make the script executable:
   ```bash
   chmod +x build-and-push.sh
   ```

2. Build and push images:
   ```bash
   ./build-and-push.sh your-username
   ```

   Or manually:
   ```bash
   # Build images
   docker build -t your-username/transfileserver-backend:latest .
   docker build -t your-username/transfileserver-frontend:latest ./frontend
   
   # Push images
   docker push your-username/transfileserver-backend:latest
   docker push your-username/transfileserver-frontend:latest
   ```

### 3. Server Deployment

1. Create project directory on server:
   ```bash
   mkdir transfileserver && cd transfileserver
   ```

2. Download production configuration:
   ```bash
   wget https://raw.githubusercontent.com/your-repo/transfileserver/main/docker-compose.prod.yml
   ```

3. Edit configuration file:
   ```bash
   nano docker-compose.prod.yml
   ```
   
   Update the following:
   - `zata/transfileserver-backend:latest` → `your-dockerhub-username/transfileserver-backend:latest`
   - `zata/transfileserver-frontend:latest` → `your-dockerhub-username/transfileserver-frontend:latest`
   - `<backend-port>` → Your desired backend port (e.g., 8000)
   - `<frontend-port>` → Your desired frontend port (e.g., 80)
   - `<backend-port>` in REACT_APP_API_URL → Same as backend port above
   
   **Important**: Ensure `REACT_APP_API_URL` contains a URL accessible from user browsers:
   - If using domain: `http://your-domain.com:8000`
   - If using IP: `http://your-server-ip:8000`
   - If local testing: `http://localhost:8000`

4. Start services:
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

5. Check status:
   ```bash
   docker-compose -f docker-compose.prod.yml ps
   docker-compose -f docker-compose.prod.yml logs
   ```

### 4. Domain and Reverse Proxy (Optional)

If using a domain, configure Nginx reverse proxy:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 5. Update Deployment

When code is updated:

1. Rebuild and push images:
   ```bash
   ./build-and-push.sh your-username
   ```

2. Pull latest images and restart on server:
   ```bash
   docker-compose -f docker-compose.prod.yml pull
   docker-compose -f docker-compose.prod.yml up -d
   ```

## Environment Variables

### Frontend Environment Variables

The frontend image supports runtime environment variable configuration. The `REACT_APP_API_URL` environment variable is dynamically replaced in the built JavaScript files when the container starts.

**Important Notes**:
- Frontend runs in user browsers, so API URL must be browser-accessible
- Cannot use Docker internal service names (e.g., `http://backend:8000`)
- Must use externally accessible addresses

### Using .env Files

Create a `.env` file to manage environment variables:

```env
DOCKERHUB_USERNAME=your-username
SERVER_DOMAIN=your-domain.com
BACKEND_PORT=8000
FRONTEND_PORT=80
API_URL=http://your-domain.com:8000
```

Then use in `docker-compose.prod.yml`:
```yaml
services:
  backend:
    image: ${DOCKERHUB_USERNAME}/transfileserver-backend:latest
    ports:
      - \"${BACKEND_PORT}:8000\"
  
  frontend:
    image: ${DOCKERHUB_USERNAME}/transfileserver-frontend:latest
    ports:
      - \"${FRONTEND_PORT}:80\"
    environment:
      - REACT_APP_API_URL=${API_URL}
```

## Manual Deployment

### Backend Deployment

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Create systemd service file `/etc/systemd/system/transfileserver.service`:
   ```ini
   [Unit]
   Description=Transfer File Server
   After=network.target
   
   [Service]
   Type=simple
   User=www-data
   WorkingDirectory=/path/to/transfileserver
   ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
   Restart=always
   RestartSec=10
   
   [Install]
   WantedBy=multi-user.target
   ```

3. Start and enable service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable transfileserver
   sudo systemctl start transfileserver
   ```

### Frontend Deployment

1. Build the frontend:
   ```bash
   cd frontend
   npm install
   npm run build
   ```

2. Configure Nginx:
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;
       root /path/to/transfileserver/frontend/build;
       index index.html;
       
       location / {
           try_files $uri $uri/ /index.html;
       }
       
       location /api/ {
           proxy_pass http://localhost:8000/;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

## Security Considerations

### Production Security Checklist

1. **Restrict CORS Origins**:
   ```python
   app.add_middleware(
       CORSMiddleware,
       allow_origins=[\"https://your-domain.com\"],
       allow_credentials=True,
       allow_methods=[\"GET\", \"POST\", \"DELETE\"],
       allow_headers=[\"*\"],
   )
   ```

2. **Add Authentication**:
   - Implement API keys or JWT tokens
   - Add user authorization for file operations

3. **File Security**:
   - Validate file types before upload
   - Implement file size limits
   - Scan files for malware

4. **Rate Limiting**:
   - Add rate limiting to prevent abuse
   - Implement request quotas per user/IP

5. **HTTPS Configuration**:
   - Use SSL/TLS certificates
   - Redirect HTTP to HTTPS

   - Consider implementing session timeouts

6. **Session Management**:
   - Implement automatic session cleanup
   - Add session timeouts to prevent resource leaks
   - Validate session ownership before cleanup

## Production Optimization

### File Storage Management

For production deployments, implement proper file storage management:

```python
# Add to main.py
import asyncio
import time
import shutil
from pathlib import Path

async def cleanup_old_files():
    \"\"\"Clean up old files to prevent disk space issues\"\"\"
    current_time = time.time()
    max_age = 24 * 60 * 60  # 24 hours
    
    for file_path in UPLOAD_DIR.glob("*"):
        if file_path.is_file():
            file_age = current_time - file_path.stat().st_mtime
            if file_age > max_age:
                try:
                    file_path.unlink()
                    print(f"Deleted old file: {file_path}")
                except Exception as e:
                    print(f"Error deleting file {file_path}: {e}")

# Run cleanup task periodically
asyncio.create_task(cleanup_old_files())
```

## Monitoring and Logging

### Health Checks

Add health check endpoints to monitor service status:

```python
@app.get(\"/health\")
async def health_check():
    return {\"status\": \"healthy\", \"timestamp\": datetime.now().isoformat()}

@app.get(\"/files/health\")
async def files_health_check():
    return {
        \"status\": \"healthy\",
        \"total_files\": len(list(UPLOAD_DIR.glob(\"*\"))),
        \"storage_dir\": str(UPLOAD_DIR),
        \"timestamp\": datetime.now().isoformat()
    }
```

### Logging Configuration

Configure structured logging for production:

```python
import logging
from datetime import datetime

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('app.log'),
        logging.StreamHandler()
    ]
)
```

### Docker Monitoring

Monitor Docker containers:

```bash
# View container logs
docker-compose logs -f

# Monitor resource usage
docker stats

# Check container health
docker-compose ps
```

## Scaling

### Load Balancing

For high-traffic scenarios, use a load balancer:

```nginx
upstream backend {
    server backend1:8000;
    server backend2:8000;
    server backend3:8000;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
    }
}
```

### Database Integration

For scalability, consider using a database for file metadata:

```python
from sqlalchemy import create_engine, Column, String, Integer, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

Base = declarative_base()

class FileMetadata(Base):
    __tablename__ = \"files\"
    
    id = Column(String, primary_key=True)
    filename = Column(String)
    size = Column(Integer)
    created_at = Column(DateTime)
```

## Troubleshooting

### Common Issues

1. **Image push failures**: Check Docker Hub login status
2. **Service startup failures**: Check port conflicts and permissions
3. **File upload failures**: Verify uploads directory permissions
4. **Frontend API connection issues**: Verify REACT_APP_API_URL configuration

### Debug Commands

```bash
# Check service logs
docker-compose logs backend
docker-compose logs frontend

# Test API connectivity
curl -X GET http://localhost:8000/files

# Check file permissions
ls -la uploads/

# Monitor system resources
htop
df -h
```

## Advantages of Docker Deployment

- ✅ Fast deployment without server-side building
- ✅ Easy version management
- ✅ Scalable to multiple servers
- ✅ Supports automated CI/CD
- ✅ Consistent environments across development and production