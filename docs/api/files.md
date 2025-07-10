# List Files

Retrieve a list of all uploaded files.

## Endpoint

**GET** `/files`

## Description

This endpoint returns a list of all files currently stored on the server, including their metadata such as file ID, filename, and size.

## Request

### Parameters

No parameters are required for this endpoint.

### Headers

No special headers are required for this endpoint.

## Response

### Success Response

**Status Code**: `200 OK`

**Content-Type**: `application/json`

```json
{
  "files": [
    {
      "file_id": "550e8400-e29b-41d4-a716-446655440000",
      "filename": "example.txt",
      "size": 1024
    },
    {
      "file_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
      "filename": "document.pdf",
      "size": 2048
    },
    {
      "file_id": "6ba7b811-9dad-11d1-80b4-00c04fd430c8",
      "filename": "6ba7b811-9dad-11d1-80b4-00c04fd430c8.txt",
      "size": 256
    }
  ]
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `files` | Array | List of file objects |
| `files[].file_id` | String | Unique identifier (UUID) of the file |
| `files[].filename` | String | Original filename or generated name for text files |
| `files[].size` | Number | File size in bytes |

### Empty Response

If no files are uploaded, the response will be:

```json
{
  "files": []
}
```

## Examples

### List All Files

**cURL**
```bash
curl -X GET "http://localhost:8000/files"
```

**Python**
```python
import requests

url = "http://localhost:8000/files"
response = requests.get(url)

if response.status_code == 200:
    data = response.json()
    files = data["files"]
    print(f"Total files: {len(files)}")
    for file in files:
        print(f"ID: {file['file_id']}")
        print(f"Name: {file['filename']}")
        print(f"Size: {file['size']} bytes")
        print("---")
else:
    print(f"Error: {response.status_code}")
```

**JavaScript (Fetch)**
```javascript
fetch('http://localhost:8000/files')
  .then(response => response.json())
  .then(data => {
    const files = data.files;
    console.log(`Total files: ${files.length}`);
    files.forEach(file => {
      console.log(`ID: ${file.file_id}`);
      console.log(`Name: ${file.filename}`);
      console.log(`Size: ${file.size} bytes`);
      console.log('---');
    });
  })
  .catch(error => console.error('Error:', error));
```

### Process Files with Metadata

**Python with file processing**
```python
import requests

url = "http://localhost:8000/files"
response = requests.get(url)

if response.status_code == 200:
    data = response.json()
    files = data["files"]
    
    # Calculate total size
    total_size = sum(file["size"] for file in files)
    print(f"Total storage used: {total_size} bytes")
    
    # Filter by file type
    text_files = [f for f in files if f["filename"].endswith(".txt")]
    print(f"Text files: {len(text_files)}")
    
    # Sort by size
    files_by_size = sorted(files, key=lambda x: x["size"], reverse=True)
    print("Largest files:")
    for file in files_by_size[:3]:  # Top 3
        print(f"  {file['filename']}: {file['size']} bytes")
```

**JavaScript with file management**
```javascript
fetch('http://localhost:8000/files')
  .then(response => response.json())
  .then(data => {
    const files = data.files;
    
    // Create file list UI
    const fileList = document.getElementById('file-list');
    fileList.innerHTML = '';
    
    files.forEach(file => {
      const fileItem = document.createElement('div');
      fileItem.className = 'file-item';
      fileItem.innerHTML = `
        <div class="file-info">
          <span class="filename">${file.filename}</span>
          <span class="filesize">${formatFileSize(file.size)}</span>
        </div>
        <div class="file-actions">
          <button onclick="downloadFile('${file.file_id}')">Download</button>
          <button onclick="deleteFile('${file.file_id}')">Delete</button>
        </div>
      `;
      fileList.appendChild(fileItem);
    });
  });

function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}
```

## Implementation Details

The files endpoint:
- Scans the `uploads/` directory for all files
- Extracts file ID from the filename prefix (before the first `_`)
- Extracts original filename:
  - For regular files: removes UUID prefix (`{uuid}_{filename}` → `{filename}`)
  - For text files: keeps full filename (`{uuid}.txt`)
- Calculates file size using `file.stat().st_size`
- Returns all files in a single response (no pagination)

## File Naming Convention

The server uses the following naming convention for stored files:
- **Regular files**: `{uuid}_{original_filename}`
- **Text files**: `{uuid}.txt`

When listing files, the API returns the original filename for regular files and the full generated filename for text files.

## Notes

- No authentication is required to list files
- The endpoint returns all files without filtering
- File sizes are returned in bytes
- The response does not include creation timestamps or other metadata
- Large directories may result in longer response times
- Consider implementing pagination for systems with many files