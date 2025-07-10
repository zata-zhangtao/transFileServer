# File Transfer Server API Documentation

Welcome to the File Transfer Server API documentation. This is a modern file transfer service built with FastAPI (Python) backend and React (TypeScript) frontend, supporting server-based file transfers with chunked upload support for large files.

## Overview

The File Transfer Server provides a comprehensive file transfer solution with server-based transfers supporting files of all sizes through chunked upload functionality.

## Key Features

### File Transfer Features
- **File Upload**: Upload files of any size with automatic UUID generation
- **Chunked Upload**: Support for large file uploads via chunked transfer
- **Text Upload**: Store text content as files
- **File Download**: Download files using unique UUIDs
- **File Management**: List and delete files

### General Features
- **CORS Support**: Cross-origin resource sharing enabled
- **Docker Support**: Full containerization support for easy deployment
- **Responsive UI**: Modern React frontend with drag-and-drop support

## Architecture

### Server-Based Transfer Architecture
```
┌─────────────────┐    HTTP API    ┌─────────────────┐
│   React Frontend │ ──────────────▶│  FastAPI Backend │
│   (TypeScript)   │                │    (Python)     │
└─────────────────┘                └─────────────────┘
                                            │
                                            ▼
                                   ┌─────────────────┐
                                   │  File Storage   │
                                   │  (uploads/ dir) │
                                   └─────────────────┘
```
┌─────────────────┐                      ┌─────────────────┐
│   Sender        │                      │   Receiver      │
│   (Browser A)   │                      │   (Browser B)   │
└─────────────────┘                      └─────────────────┘
         │                                        │
         │           WebRTC Data Channel          │
         │ ══════════════════════════════════════ │
         │                                        │
         │                                        │
         ▼              Signaling Server          ▼
┌─────────────────────────────────────────────────────────┐
│              FastAPI Backend                           │

## Technology Stack

### Backend
- **FastAPI**: Modern, fast web framework for building APIs
- **Python 3.8+**: Programming language
- **Uvicorn**: ASGI server for production
- **UUID**: For unique file identification

### Frontend
- **React 18**: JavaScript library for building user interfaces
- **TypeScript**: Type-safe JavaScript
- **Modern CSS**: Responsive design with drag-and-drop

## Quick Start

1. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Run Backend Server**
   ```bash
   python main.py
   ```

3. **Run Frontend** (in another terminal)
   ```bash
   cd frontend
   npm install
   npm start
   ```

4. **Access the Application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs

## API Endpoints

### Server-Based Transfer Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/upload` | Upload files or text content |
| `POST` | `/upload-chunk` | Upload file chunks for large files |
| `GET` | `/upload-status/{file_id}` | Check chunked upload status |
| `GET` | `/download/{file_id}` | Download file by UUID |
| `GET` | `/files` | List all available files |
| `DELETE` | `/delete/{file_id}` | Delete file by UUID |


## Next Steps

- [Getting Started Guide](getting-started.md) - Detailed setup instructions
- [API Reference](api/overview.md) - Complete API documentation
- [Examples](examples.md) - Usage examples for server-based transfers
- [Deployment Guide](deployment.md) - Production deployment instructions