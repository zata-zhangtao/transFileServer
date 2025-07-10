# Delete Files

Delete files by their unique identifier.

## Endpoint

**DELETE** `/delete/{file_id}`

## Description

This endpoint allows you to permanently delete a file from the server using its unique UUID. Once deleted, the file cannot be recovered.

## Request

### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file_id` | String (UUID) | Yes | The unique identifier of the file to delete |

### Headers

No special headers are required for this endpoint.

## Response

### Success Response

**Status Code**: `200 OK`

**Content-Type**: `application/json`

```json
{
  "message": "File deleted successfully"
}
```

### Error Responses

#### File Not Found

**Status Code**: `404 Not Found`

```json
{
  "detail": "File not found"
}
```

#### Server Error

**Status Code**: `500 Internal Server Error`

```json
{
  "detail": "Error deleting file: [error message]"
}
```

## Examples

### Delete File

**cURL**
```bash
curl -X DELETE "http://localhost:8000/delete/550e8400-e29b-41d4-a716-446655440000"
```

**Python**
```python
import requests

file_id = "550e8400-e29b-41d4-a716-446655440000"
url = f"http://localhost:8000/delete/{file_id}"
response = requests.delete(url)

if response.status_code == 200:
    print("File deleted successfully")
    print(response.json())
elif response.status_code == 404:
    print("File not found")
else:
    print(f"Error: {response.json()}")
```

**JavaScript (Fetch)**
```javascript
const fileId = "550e8400-e29b-41d4-a716-446655440000";
fetch(`http://localhost:8000/delete/${fileId}`, {
  method: 'DELETE'
})
  .then(response => response.json())
  .then(data => {
    if (data.message) {
      console.log('Success:', data.message);
    } else {
      console.error('Error:', data.detail);
    }
  })
  .catch(error => console.error('Error:', error));
```

### Delete with Confirmation

**Python with confirmation**
```python
import requests

def delete_file_with_confirmation(file_id):
    # First, get file info
    list_url = "http://localhost:8000/files"
    response = requests.get(list_url)
    
    if response.status_code == 200:
        files = response.json()["files"]
        file_to_delete = None
        
        for file in files:
            if file["file_id"] == file_id:
                file_to_delete = file
                break
        
        if file_to_delete:
            print(f"File to delete: {file_to_delete['filename']}")
            print(f"Size: {file_to_delete['size']} bytes")
            
            confirm = input("Are you sure you want to delete this file? (y/N): ")
            if confirm.lower() == 'y':
                delete_url = f"http://localhost:8000/delete/{file_id}"
                delete_response = requests.delete(delete_url)
                
                if delete_response.status_code == 200:
                    print("File deleted successfully")
                else:
                    print(f"Error deleting file: {delete_response.json()}")
            else:
                print("Delete cancelled")
        else:
            print("File not found")
    else:
        print("Error retrieving file list")

# Usage
delete_file_with_confirmation("550e8400-e29b-41d4-a716-446655440000")
```

### Batch Delete

**Python batch delete**
```python
import requests

def delete_multiple_files(file_ids):
    results = []
    
    for file_id in file_ids:
        url = f"http://localhost:8000/delete/{file_id}"
        response = requests.delete(url)
        
        if response.status_code == 200:
            results.append({"file_id": file_id, "status": "deleted"})
        elif response.status_code == 404:
            results.append({"file_id": file_id, "status": "not_found"})
        else:
            results.append({"file_id": file_id, "status": "error", "detail": response.json()})
    
    return results

# Usage
file_ids = [
    "550e8400-e29b-41d4-a716-446655440000",
    "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
    "6ba7b811-9dad-11d1-80b4-00c04fd430c8"
]

results = delete_multiple_files(file_ids)
for result in results:
    print(f"File {result['file_id']}: {result['status']}")
```

**JavaScript with UI integration**
```javascript
async function deleteFileWithUI(fileId) {
  if (!confirm('Are you sure you want to delete this file?')) {
    return;
  }
  
  try {
    const response = await fetch(`http://localhost:8000/delete/${fileId}`, {
      method: 'DELETE'
    });
    
    const data = await response.json();
    
    if (response.ok) {
      // Remove file from UI
      const fileElement = document.getElementById(`file-${fileId}`);
      if (fileElement) {
        fileElement.remove();
      }
      
      // Show success message
      showNotification('File deleted successfully', 'success');
    } else {
      showNotification(`Error: ${data.detail}`, 'error');
    }
  } catch (error) {
    console.error('Error:', error);
    showNotification('Network error occurred', 'error');
  }
}

function showNotification(message, type) {
  const notification = document.createElement('div');
  notification.className = `notification ${type}`;
  notification.textContent = message;
  document.body.appendChild(notification);
  
  setTimeout(() => {
    notification.remove();
  }, 3000);
}
```

## Implementation Details

The delete endpoint:
- Uses glob pattern matching to find files by UUID prefix
- Locates the file using `UPLOAD_DIR.glob(f"{file_id}*")`
- Deletes the file using `file_path.unlink()`
- Returns success message or appropriate error
- Handles both regular files and text files uniformly

## File Matching Logic

The server uses the same glob pattern matching as the download endpoint:
1. Search for files matching `{file_id}*` in the uploads directory
2. Delete the first match (UUIDs should be unique)
3. If no matches found, return 404 error
4. If deletion fails, return 500 error with details

## Error Handling

The delete endpoint handles several error scenarios:
- **File not found**: Returns 404 when no file matches the UUID
- **Permission errors**: Returns 500 if the file cannot be deleted due to permissions
- **File system errors**: Returns 500 for other file system related errors

## Notes

- **Permanent deletion**: Files are permanently removed from the file system
- **No recovery**: There is no way to recover deleted files
- **No authentication**: Anyone with the file ID can delete the file
- **Atomic operation**: File deletion is atomic - either succeeds completely or fails
- **No cascade effects**: Deleting a file doesn't affect other files or operations
- **Consider backups**: In production, consider implementing file backup/versioning before deletion