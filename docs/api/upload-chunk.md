# Chunked File Upload

The chunked upload endpoints allow for uploading large files in smaller pieces, providing better reliability and progress tracking for large file transfers.

## Overview

Chunked upload works by:
1. **Splitting large files** into smaller chunks on the client side
2. **Uploading chunks individually** with progress tracking
3. **Automatic merging** of chunks when all pieces are received
4. **Cleanup** of temporary chunk files after merge

## Endpoints

### Upload File Chunk

**POST** `/upload-chunk`

Uploads a single chunk of a large file.

#### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file_id` | String | Yes | Unique identifier for the file |
| `chunk_index` | Integer | Yes | Index of the chunk (0-based) |
| `total_chunks` | Integer | Yes | Total number of chunks |
| `filename` | String | Yes | Original filename |
| `chunk` | File | Yes | The chunk data |

#### Request Example

```bash
curl -X POST "http://localhost:8000/upload-chunk" \
  -F "file_id=550e8400-e29b-41d4-a716-446655440000" \
  -F "chunk_index=0" \
  -F "total_chunks=5" \
  -F "filename=large_file.pdf" \
  -F "chunk=@chunk_000.bin"
```

#### Response (Upload in Progress)

```json
{
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "filename": "large_file.pdf",
  "type": "file",
  "status": "uploading",
  "uploaded_chunks": 3,
  "total_chunks": 5
}
```

#### Response (Upload Complete)

```json
{
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "filename": "large_file.pdf",
  "type": "file",
  "status": "completed",
  "uploaded_chunks": 5,
  "total_chunks": 5
}
```

### Check Upload Status

**GET** `/upload-status/{file_id}`

Checks the status of a chunked upload.

#### Response (Upload in Progress)

```json
{
  "status": "uploading",
  "uploaded_chunks": 3,
  "file_exists": false
}
```

#### Response (Upload Complete)

```json
{
  "status": "completed",
  "file_exists": true
}
```

#### Response (Upload Not Found)

```json
{
  "status": "not_found",
  "file_exists": false
}
```

## Implementation Guide

### Frontend Implementation

#### 1. File Chunking

```javascript
const CHUNK_SIZE = 1024 * 1024; // 1MB chunks

function createChunks(file) {
  const chunks = [];
  let start = 0;
  
  while (start < file.size) {
    const end = Math.min(start + CHUNK_SIZE, file.size);
    chunks.push(file.slice(start, end));
    start = end;
  }
  
  return chunks;
}
```

#### 2. Upload Chunks

```javascript
async function uploadFileInChunks(file) {
  const chunks = createChunks(file);
  const fileId = generateUUID();
  
  for (let i = 0; i < chunks.length; i++) {
    const formData = new FormData();
    formData.append('file_id', fileId);
    formData.append('chunk_index', i.toString());
    formData.append('total_chunks', chunks.length.toString());
    formData.append('filename', file.name);
    formData.append('chunk', chunks[i]);
    
    const response = await fetch('/upload-chunk', {
      method: 'POST',
      body: formData
    });
    
    const result = await response.json();
    
    // Update progress
    updateProgress(i + 1, chunks.length);
    
    if (result.status === 'completed') {
      console.log('Upload completed!');
      break;
    }
  }
}
```

#### 3. Progress Tracking

```javascript
function updateProgress(uploadedChunks, totalChunks) {
  const progress = (uploadedChunks / totalChunks) * 100;
  console.log(`Upload progress: ${progress.toFixed(1)}%`);
  
  // Update UI progress bar
  const progressBar = document.getElementById('progress-bar');
  progressBar.style.width = `${progress}%`;
  progressBar.textContent = `${progress.toFixed(1)}%`;
}
```

#### 4. Resume Upload

```javascript
async function resumeUpload(fileId, file) {
  // Check current status
  const statusResponse = await fetch(`/upload-status/${fileId}`);
  const status = await statusResponse.json();
  
  if (status.status === 'completed') {
    console.log('Upload already completed');
    return;
  }
  
  if (status.status === 'uploading') {
    // Resume from where we left off
    const chunks = createChunks(file);
    const startIndex = status.uploaded_chunks;
    
    for (let i = startIndex; i < chunks.length; i++) {
      // Continue uploading remaining chunks
      await uploadChunk(fileId, i, chunks[i], file.name, chunks.length);
    }
  }
}
```

### Backend Implementation Details

#### Chunk Storage

Chunks are temporarily stored in the `chunks/` directory:
```
chunks/
├── 550e8400-e29b-41d4-a716-446655440000/
│   ├── chunk_000000
│   ├── chunk_000001
│   ├── chunk_000002
│   └── ...
```

#### Chunk Merging

When all chunks are received:
1. **Merge chunks** in sequential order
2. **Save final file** to `uploads/` directory
3. **Clean up** temporary chunk files
4. **Return completion status**

#### Error Handling

```python
try:
    # Save chunk
    chunk_path = file_chunks_dir / f"chunk_{chunk_index:06d}"
    with open(chunk_path, "wb") as buffer:
        shutil.copyfileobj(chunk.file, buffer)
    
    # Check if upload is complete
    if uploaded_chunks == total_chunks:
        # Merge and cleanup
        merge_chunks(file_id, filename, total_chunks)
        
except Exception as e:
    raise HTTPException(status_code=500, detail=f"Chunk upload failed: {str(e)}")
```

## Best Practices

### Client-Side

1. **Reasonable Chunk Size**: Use 1-5MB chunks for optimal performance
2. **Progress Tracking**: Show upload progress to users
3. **Error Recovery**: Implement retry logic for failed chunks
4. **Concurrent Uploads**: Limit concurrent chunk uploads to avoid overwhelming the server
5. **Validation**: Validate file integrity after upload completion

### Server-Side

1. **Cleanup**: Automatically remove incomplete uploads after timeout
2. **Disk Space**: Monitor disk space for chunk storage
3. **Concurrency**: Handle multiple concurrent uploads efficiently
4. **Validation**: Verify chunk order and completeness before merging

## Example Usage

### Python Client

```python
import requests
import os

def upload_file_chunks(file_path, chunk_size=1024*1024):
    with open(file_path, 'rb') as f:
        file_size = os.path.getsize(file_path)
        total_chunks = (file_size + chunk_size - 1) // chunk_size
        file_id = str(uuid.uuid4())
        filename = os.path.basename(file_path)
        
        for chunk_index in range(total_chunks):
            chunk_data = f.read(chunk_size)
            
            files = {
                'chunk': ('chunk', chunk_data, 'application/octet-stream')
            }
            
            data = {
                'file_id': file_id,
                'chunk_index': chunk_index,
                'total_chunks': total_chunks,
                'filename': filename
            }
            
            response = requests.post('http://localhost:8000/upload-chunk',
                                   files=files, data=data)
            
            result = response.json()
            print(f"Chunk {chunk_index + 1}/{total_chunks} uploaded")
            
            if result['status'] == 'completed':
                print(f"Upload completed! File ID: {file_id}")
                break
```

### JavaScript Client

```javascript
class ChunkedUploader {
  constructor(apiUrl = 'http://localhost:8000') {
    this.apiUrl = apiUrl;
    this.chunkSize = 1024 * 1024; // 1MB
  }
  
  async uploadFile(file, onProgress = null) {
    const chunks = this.createChunks(file);
    const fileId = this.generateUUID();
    
    for (let i = 0; i < chunks.length; i++) {
      await this.uploadChunk(fileId, i, chunks[i], file.name, chunks.length);
      
      if (onProgress) {
        onProgress(i + 1, chunks.length);
      }
    }
    
    return fileId;
  }
  
  createChunks(file) {
    const chunks = [];
    let start = 0;
    
    while (start < file.size) {
      const end = Math.min(start + this.chunkSize, file.size);
      chunks.push(file.slice(start, end));
      start = end;
    }
    
    return chunks;
  }
  
  async uploadChunk(fileId, chunkIndex, chunk, filename, totalChunks) {
    const formData = new FormData();
    formData.append('file_id', fileId);
    formData.append('chunk_index', chunkIndex.toString());
    formData.append('total_chunks', totalChunks.toString());
    formData.append('filename', filename);
    formData.append('chunk', chunk);
    
    const response = await fetch(`${this.apiUrl}/upload-chunk`, {
      method: 'POST',
      body: formData
    });
    
    return await response.json();
  }
  
  generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }
}
```

## Error Handling

### Common Error Responses

#### Invalid Parameters
```json
{
  "detail": "Missing required parameter: file_id"
}
```

#### Chunk Upload Failure
```json
{
  "detail": "Chunk upload failed: disk space full"
}
```

#### File Not Found
```json
{
  "detail": "File not found"
}
```

### Recommended Error Handling

1. **Retry Logic**: Implement exponential backoff for failed uploads
2. **Timeout Handling**: Set reasonable timeouts for chunk uploads
3. **Cleanup**: Clean up partial uploads on client errors
4. **User Feedback**: Provide clear error messages to users

## Limitations

- **Chunk Size**: Optimize chunk size based on network conditions
- **Concurrent Uploads**: Limit concurrent chunk uploads to avoid server overload
- **Storage**: Temporary chunk storage requires additional disk space
- **Timeout**: Incomplete uploads should be cleaned up after timeout
- **Memory**: Large files may require careful memory management