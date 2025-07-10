# Download Files

Download files by their unique identifier.

## Endpoint

**GET** `/download/{file_id}`

## Description

This endpoint allows you to download a file using its unique UUID. The server will locate the file and return it as a binary stream with appropriate headers.

## Request

### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file_id` | String (UUID) | Yes | The unique identifier of the file to download |

### Headers

No special headers are required for this endpoint.

## Response

### Success Response

**Status Code**: `200 OK`

**Content-Type**: `application/octet-stream`

**Headers**:
- `Content-Disposition: attachment; filename="{original_filename}"`
- `Content-Length: {file_size}`
- `Accept-Ranges: bytes`

The response body contains the binary file data.

### Error Response

**Status Code**: `404 Not Found`

```json
{
  "detail": "File not found"
}
```

## Examples

### Download File Example

**cURL**
```bash
curl -X GET "http://localhost:8000/download/550e8400-e29b-41d4-a716-446655440000" \
  -o downloaded_file.txt
```

**Python**
```python
import requests

url = "http://localhost:8000/download/550e8400-e29b-41d4-a716-446655440000"
response = requests.get(url)

if response.status_code == 200:
    with open("downloaded_file.txt", "wb") as f:
        f.write(response.content)
    print("File downloaded successfully")
else:
    print(f"Error: {response.json()}")
```

**JavaScript (Fetch with Progress)**
```javascript
const fileId = "550e8400-e29b-41d4-a716-446655440000";

// Using XMLHttpRequest for progress tracking
const xhr = new XMLHttpRequest();

xhr.addEventListener('progress', (event) => {
  if (event.lengthComputable) {
    const progress = Math.round((event.loaded / event.total) * 100);
    console.log(`Download progress: ${progress}%`);
  }
});

xhr.addEventListener('load', () => {
  if (xhr.status === 200) {
    const blob = new Blob([xhr.response]);
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    
    // Extract filename from Content-Disposition header
    const contentDisposition = xhr.getResponseHeader('Content-Disposition');
    let filename = 'downloaded_file.txt';
    
    if (contentDisposition && contentDisposition.includes('filename=')) {
      const match = contentDisposition.match(/filename="?([^"]+)"?/);
      if (match) {
        filename = match[1];
      }
    }
    
    a.download = filename;
    a.click();
    window.URL.revokeObjectURL(url);
  }
});

xhr.open('GET', `http://localhost:8000/download/${fileId}`, true);
xhr.responseType = 'blob';
xhr.send();
```

### Download with Proper Filename

**Python with filename extraction**
```python
import requests
from urllib.parse import unquote

url = "http://localhost:8000/download/550e8400-e29b-41d4-a716-446655440000"
response = requests.get(url)

if response.status_code == 200:
    # Extract filename from Content-Disposition header
    content_disposition = response.headers.get('Content-Disposition', '')
    if 'filename=' in content_disposition:
        filename = content_disposition.split('filename=')[1].strip('"')
        filename = unquote(filename)
    else:
        filename = "downloaded_file"
    
    with open(filename, "wb") as f:
        f.write(response.content)
    print(f"File downloaded as: {filename}")
else:
    print(f"Error: {response.json()}")
```

## Implementation Details

The download endpoint:
- Uses glob pattern matching to find files by UUID prefix
- Returns the first matching file (should be unique)
- Extracts the original filename from the stored filename pattern
- For files: `{uuid}_{original_filename}` → `{original_filename}`
- For text files: `{uuid}.txt` → `{uuid}.txt`
- Sets `Content-Disposition` header for proper filename handling
- Includes `Content-Length` header with file size for progress tracking
- Includes `Accept-Ranges: bytes` header for range request support
- Returns files as `application/octet-stream` for universal compatibility

## File Matching Logic

The server uses glob pattern matching to find files:
1. Search for files matching `{file_id}*` in the uploads directory
2. Return the first match (UUIDs should be unique)
3. If no matches found, return 404 error

## Notes

- Files are served as binary streams regardless of their original type
- The `Content-Disposition` header ensures proper filename handling in browsers
- No authentication is required to download files
- File access is based solely on knowing the UUID
- Large files are streamed efficiently without loading into memory