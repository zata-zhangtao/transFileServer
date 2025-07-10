# API Overview

This section provides a comprehensive overview of the File Transfer Server API endpoints, request/response formats, and authentication requirements.

## Base URL

The API is available at:
- **Development**: `http://localhost:8000`
- **Production**: `https://your-domain.com`

## Authentication

Currently, the API does not require authentication. All endpoints are publicly accessible.

!!! warning "Production Consideration"
    For production deployments, consider implementing authentication and authorization mechanisms to secure your file transfer operations.

## Request/Response Format

All API endpoints use JSON format for structured data and multipart/form-data for file uploads.

### Content Types

| Endpoint | Request Content-Type | Response Content-Type |
|----------|---------------------|----------------------|
| `POST /upload` | `multipart/form-data` | `application/json` |
| `GET /download/{file_id}` | N/A | `application/octet-stream` |
| `GET /files` | N/A | `application/json` |
| `DELETE /delete/{file_id}` | N/A | `application/json` |

## Error Handling

The API uses standard HTTP status codes to indicate success or failure:

### Success Codes
- **200 OK**: Request successful
- **201 Created**: Resource created successfully

### Error Codes
- **400 Bad Request**: Invalid request parameters
- **404 Not Found**: Resource not found
- **500 Internal Server Error**: Server error

### Error Response Format

```json
{
  "detail": "Error message description"
}
```

## CORS Policy

The API is configured with CORS (Cross-Origin Resource Sharing) enabled for all origins during development:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

!!! warning "Production Security"
    In production, restrict CORS origins to only trusted domains for security.

## File Storage

### Server-Based Storage
Files are stored in the `uploads/` directory with the following naming convention:
- **Regular files**: `{uuid}_{original_filename}`
- **Text content**: `{uuid}.txt`

- Files are processed and stored securely on the server
- Chunked uploads are assembled and stored as complete files
- Temporary chunk files are cleaned up after assembly

## Rate Limiting

Currently, no rate limiting is implemented. Consider adding rate limiting for production deployments.

## API Endpoints Summary

### Server-Based Transfer Endpoints

| Endpoint | Method | Purpose | Authentication |
|----------|--------|---------|----------------|
| [/upload](upload.md) | POST | Upload files or text | None |
| [/upload-chunk](upload-chunk.md) | POST | Upload file chunks | None |
| [/upload-status/{file_id}](upload-chunk.md) | GET | Check upload status | None |
| [/download/{file_id}](download.md) | GET | Download file by ID | None |
| [/files](files.md) | GET | List all files | None |
| [/delete/{file_id}](delete.md) | DELETE | Delete file by ID | None |


## Interactive API Documentation

FastAPI automatically generates interactive API documentation:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`