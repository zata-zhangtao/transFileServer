# Examples

This page provides practical examples of how to use the File Transfer Server API in different scenarios for server-based file transfers.

## Basic File Operations

### Upload and Download Workflow

```python
import requests
import os

# 1. Upload a file
def upload_file(file_path):
    url = "http://localhost:8000/upload"
    with open(file_path, 'rb') as file:
        files = {'file': file}
        response = requests.post(url, files=files)
        return response.json()

# 2. Download a file
def download_file(file_id, output_path):
    url = f"http://localhost:8000/download/{file_id}"
    response = requests.get(url)
    if response.status_code == 200:
        with open(output_path, 'wb') as file:
            file.write(response.content)
        return True
    return False

# Example usage
result = upload_file("example.txt")
file_id = result['file_id']
print(f"File uploaded with ID: {file_id}")

if download_file(file_id, "downloaded_example.txt"):
    print("File downloaded successfully")
```

### Text Content Management

```python
import requests

# Upload text content
def upload_text(content):
    url = "http://localhost:8000/upload"
    data = {'text': content}
    response = requests.post(url, data=data)
    return response.json()

# Download text content
def download_text(file_id):
    url = f"http://localhost:8000/download/{file_id}"
    response = requests.get(url)
    if response.status_code == 200:
        return response.text
    return None

# Example usage
text_content = "This is a sample text content"
result = upload_text(text_content)
file_id = result['file_id']

downloaded_text = download_text(file_id)
print(f"Downloaded text: {downloaded_text}")
```

## Web Browser Integration

### HTML File Upload Form

```html
<!DOCTYPE html>
<html>
<head>
    <title>File Upload</title>
</head>
<body>
    <h1>File Upload</h1>
    
    <form id="uploadForm" enctype="multipart/form-data">
        <div>
            <label>Upload File:</label>
            <input type="file" id="fileInput" name="file">
        </div>
        <div>
            <label>Or Enter Text:</label>
            <textarea id="textInput" name="text" rows="4" cols="50"></textarea>
        </div>
        <button type="submit">Upload</button>
    </form>

    <div id="result"></div>

    <script>
        document.getElementById('uploadForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const formData = new FormData();
            const fileInput = document.getElementById('fileInput');
            const textInput = document.getElementById('textInput');
            
            if (fileInput.files.length > 0) {
                formData.append('file', fileInput.files[0]);
            } else if (textInput.value.trim()) {
                formData.append('text', textInput.value);
            } else {
                alert('Please select a file or enter text');
                return;
            }
            
            try {
                const response = await fetch('http://localhost:8000/upload', {
                    method: 'POST',
                    body: formData
                });
                
                const result = await response.json();
                document.getElementById('result').innerHTML = 
                    `<p>Upload successful! File ID: ${result.file_id}</p>`;
            } catch (error) {
                document.getElementById('result').innerHTML = 
                    `<p>Error: ${error.message}</p>`;
            }
        });
    </script>
</body>
</html>
```

### JavaScript File Manager

```javascript
class FileManager {
    constructor(apiUrl = 'http://localhost:8000') {
        this.apiUrl = apiUrl;
    }

    async uploadFile(file) {
        const formData = new FormData();
        formData.append('file', file);
        
        const response = await fetch(`${this.apiUrl}/upload`, {
            method: 'POST',
            body: formData
        });
        
        return await response.json();
    }

    async uploadText(text) {
        const formData = new FormData();
        formData.append('text', text);
        
        const response = await fetch(`${this.apiUrl}/upload`, {
            method: 'POST',
            body: formData
        });
        
        return await response.json();
    }

    async downloadFile(fileId) {
        const response = await fetch(`${this.apiUrl}/download/${fileId}`);
        return await response.blob();
    }

    async listFiles() {
        const response = await fetch(`${this.apiUrl}/files`);
        return await response.json();
    }

    async deleteFile(fileId) {
        const response = await fetch(`${this.apiUrl}/delete/${fileId}`, {
            method: 'DELETE'
        });
        return await response.json();
    }
}

// Usage example
const fileManager = new FileManager();

// Upload and manage files
async function example() {
    // Upload text
    const textResult = await fileManager.uploadText("Hello, World!");
    console.log('Text uploaded:', textResult);
    
    // List all files
    const files = await fileManager.listFiles();
    console.log('Available files:', files);
    
    // Download a file
    const blob = await fileManager.downloadFile(textResult.file_id);
    console.log('Downloaded file size:', blob.size);
    
    // Delete a file
    const deleteResult = await fileManager.deleteFile(textResult.file_id);
    console.log('Delete result:', deleteResult);
}
```

## Command Line Tools

### Bash Script for File Operations

```bash
#!/bin/bash

API_URL="http://localhost:8000"

# Function to upload a file
upload_file() {
    local file_path="$1"
    if [ ! -f "$file_path" ]; then
        echo "File not found: $file_path"
        return 1
    fi
    
    curl -X POST "$API_URL/upload" -F "file=@$file_path"
}

# Function to upload text
upload_text() {
    local text="$1"
    curl -X POST "$API_URL/upload" -F "text=$text"
}

# Function to download a file
download_file() {
    local file_id="$1"
    local output_path="$2"
    curl -X GET "$API_URL/download/$file_id" -o "$output_path"
}

# Function to list files
list_files() {
    curl -X GET "$API_URL/files" | jq '.'
}

# Function to delete a file
delete_file() {
    local file_id="$1"
    curl -X DELETE "$API_URL/delete/$file_id"
}

# Example usage
echo "Uploading file..."
UPLOAD_RESULT=$(upload_file "example.txt")
FILE_ID=$(echo $UPLOAD_RESULT | jq -r '.file_id')

echo "File uploaded with ID: $FILE_ID"

echo "Listing files..."
list_files

echo "Downloading file..."
download_file "$FILE_ID" "downloaded_example.txt"

echo "Deleting file..."
delete_file "$FILE_ID"
```

## Advanced Use Cases

### Batch File Processing

```python
import requests
import os
import concurrent.futures
from pathlib import Path

class BatchFileManager:
    def __init__(self, api_url="http://localhost:8000"):
        self.api_url = api_url
    
    def upload_file(self, file_path):
        """Upload a single file"""
        url = f"{self.api_url}/upload"
        with open(file_path, 'rb') as file:
            files = {'file': file}
            response = requests.post(url, files=files)
            return {
                'file_path': file_path,
                'result': response.json(),
                'success': response.status_code == 200
            }
    
    def upload_directory(self, directory_path, max_workers=5):
        """Upload all files in a directory"""
        directory = Path(directory_path)
        if not directory.exists():
            raise ValueError(f"Directory not found: {directory_path}")
        
        files = [f for f in directory.rglob('*') if f.is_file()]
        results = []
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            future_to_file = {
                executor.submit(self.upload_file, file_path): file_path 
                for file_path in files
            }
            
            for future in concurrent.futures.as_completed(future_to_file):
                result = future.result()
                results.append(result)
                
                if result['success']:
                    print(f"✓ Uploaded: {result['file_path']}")
                else:
                    print(f"✗ Failed: {result['file_path']}")
        
        return results
    
    def cleanup_old_files(self, keep_recent=10):
        """Delete old files, keeping only the most recent ones"""
        response = requests.get(f"{self.api_url}/files")
        if response.status_code != 200:
            return False
        
        files = response.json()['files']
        
        # Sort by file_id (UUID contains timestamp information)
        files.sort(key=lambda x: x['file_id'])
        
        # Delete old files
        files_to_delete = files[:-keep_recent] if len(files) > keep_recent else []
        
        for file_info in files_to_delete:
            delete_response = requests.delete(f"{self.api_url}/delete/{file_info['file_id']}")
            if delete_response.status_code == 200:
                print(f"Deleted: {file_info['filename']}")
        
        return True

# Example usage
batch_manager = BatchFileManager()

# Upload all files in a directory
results = batch_manager.upload_directory("./documents")
print(f"Uploaded {sum(1 for r in results if r['success'])} files")

# Cleanup old files
batch_manager.cleanup_old_files(keep_recent=5)
```

### File Synchronization

```python
import requests
import hashlib
import os
from pathlib import Path

class FileSynchronizer:
    def __init__(self, api_url="http://localhost:8000"):
        self.api_url = api_url
    
    def get_file_hash(self, file_path):
        """Calculate MD5 hash of a file"""
        hash_md5 = hashlib.md5()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()
    
    def sync_file(self, local_path, remote_file_id=None):
        """Sync a local file with the remote server"""
        if not os.path.exists(local_path):
            if remote_file_id:
                # Download from remote
                return self.download_file(remote_file_id, local_path)
            else:
                print(f"File not found: {local_path}")
                return False
        
        # Upload to remote
        return self.upload_file(local_path)
    
    def upload_file(self, file_path):
        """Upload file to server"""
        url = f"{self.api_url}/upload"
        with open(file_path, 'rb') as file:
            files = {'file': file}
            response = requests.post(url, files=files)
            return response.json() if response.status_code == 200 else None
    
    def download_file(self, file_id, output_path):
        """Download file from server"""
        url = f"{self.api_url}/download/{file_id}"
        response = requests.get(url)
        if response.status_code == 200:
            with open(output_path, 'wb') as file:
                file.write(response.content)
            return True
        return False

# Example usage
sync = FileSynchronizer()

# Sync a local file
result = sync.sync_file("important_document.pdf")
if result:
    print(f"File synced with ID: {result['file_id']}")
```

These examples demonstrate various ways to integrate with the File Transfer Server API, from simple file operations to complex batch processing and synchronization scenarios.