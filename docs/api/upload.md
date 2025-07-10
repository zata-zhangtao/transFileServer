# Upload Files

Upload files or text content to the server using various methods.

## Upload Methods

The File Transfer Server supports multiple upload methods:

1. **Standard Upload** (this endpoint): Single request upload for files up to 10MB
2. **[Chunked Upload](upload-chunk.md)**: Multi-part upload for large files with progress tracking

## Endpoint

**POST** `/upload`

## Description

This endpoint allows you to upload either a file or text content in a single request. The server will generate a unique UUID for the uploaded content and store it in the uploads directory.

## Request

### Content-Type
`multipart/form-data`

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file` | File | No* | Binary file to upload |
| `text` | String | No* | Text content to store |

*Either `file` or `text` must be provided, but not both.

### File Upload

When uploading a file, the server will:
1. Generate a unique UUID for the file
2. Store the file as `{uuid}_{original_filename}` in the uploads directory
3. Return the file ID and metadata

### Text Upload

When uploading text content, the server will:
1. Generate a unique UUID for the text
2. Store the text as `{uuid}.txt` in the uploads directory
3. Return the file ID and metadata

## Response

### Success Response

**Status Code**: `200 OK`

#### File Upload Response
```json
{
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "filename": "example.txt",
  "type": "file"
}
```

#### Text Upload Response
```json
{
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "filename": "550e8400-e29b-41d4-a716-446655440000.txt",
  "type": "text"
}
```

### Error Response

**Status Code**: `400 Bad Request`

```json
{
  "detail": "Either file or text must be provided"
}
```

## Examples

### File Upload Example

**cURL**
```bash
curl -X POST "http://localhost:8000/upload" \
  -F "file=@/path/to/your/file.txt"
```

**Python**
```python
import requests

url = "http://localhost:8000/upload"
files = {"file": open("example.txt", "rb")}
response = requests.post(url, files=files)
print(response.json())
```

**JavaScript (Fetch)**
```javascript
const formData = new FormData();
formData.append('file', fileInput.files[0]);

fetch('http://localhost:8000/upload', {
  method: 'POST',
  body: formData
})
.then(response => response.json())
.then(data => console.log(data));
```

### Text Upload Example

**cURL**
```bash
curl -X POST "http://localhost:8000/upload" \
  -F "text=Hello, World!"
```

**Python**
```python
import requests

url = "http://localhost:8000/upload"
data = {"text": "Hello, World!"}
response = requests.post(url, data=data)
print(response.json())
```

**JavaScript (Fetch)**
```javascript
const formData = new FormData();
formData.append('text', 'Hello, World!');

fetch('http://localhost:8000/upload', {
  method: 'POST',
  body: formData
})
.then(response => response.json())
.then(data => console.log(data));
```

## Implementation Details

The upload endpoint:
- Uses `uuid.uuid4()` to generate unique file identifiers
- Stores files in the `uploads/` directory
- For files: saves as `{uuid}_{original_filename}`
- For text: saves as `{uuid}.txt`
- Returns metadata including file ID, filename, and type

## File Size Limitations

### Standard Upload
- **Maximum file size**: 50MB (configurable in frontend)
- **Recommended size**: Up to 10MB for optimal performance
- **Memory usage**: Entire file is loaded into memory during upload

### Large File Uploads
For files larger than 50MB, use the [chunked upload endpoint](upload-chunk.md) which provides:
- Support for files of any size
- Progress tracking
- Resume capability
- Better memory efficiency

## Notes

- Standard uploads have a 10MB size limit enforced by the frontend, larger files use chunked upload
- No file type restrictions are enforced
- The UUID is used as the primary identifier for all subsequent operations
- Text content is stored as UTF-8 encoded files
- For large files, consider using [chunked upload](upload-chunk.md)