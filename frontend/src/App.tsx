import React, { useState, useEffect } from 'react';
import './App.css';

interface FileInfo {
  file_id: string;
  filename: string;
  size: number;
}

function App() {
  const [files, setFiles] = useState<FileInfo[]>([]);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [textContent, setTextContent] = useState('');
  const [uploadStatus, setUploadStatus] = useState('');
  const [downloadId, setDownloadId] = useState('');

  const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8000';

  const fetchFiles = async () => {
    try {
      const response = await fetch(`${API_BASE}/files`);
      const data = await response.json();
      setFiles(data.files);
    } catch (error) {
      console.error('Error fetching files:', error);
    }
  };

  useEffect(() => {
    fetchFiles();
  }, []);

  const handleFileUpload = async () => {
    if (!selectedFile && !textContent) {
      setUploadStatus('Please select a file or enter text');
      return;
    }

    const formData = new FormData();
    if (selectedFile) {
      formData.append('file', selectedFile);
    }
    if (textContent) {
      formData.append('text', textContent);
    }

    try {
      const response = await fetch(`${API_BASE}/upload`, {
        method: 'POST',
        body: formData,
      });

      if (response.ok) {
        const result = await response.json();
        setUploadStatus(`Upload successful! File ID: ${result.file_id}`);
        setSelectedFile(null);
        setTextContent('');
        fetchFiles();
      } else {
        setUploadStatus('Upload failed');
      }
    } catch (error) {
      setUploadStatus('Upload error');
      console.error('Error:', error);
    }
  };

  const handleDownload = async (fileId: string, filename?: string) => {
    try {
      const response = await fetch(`${API_BASE}/download/${fileId}`);
      if (response.ok) {
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename || response.headers.get('Content-Disposition')?.split('filename=')[1] || 'download';
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      } else {
        window.alert('Download failed');
      }
    } catch (error) {
      window.alert('Download error');
      console.error('Error:', error);
    }
  };

  const handleDownloadById = async () => {
    if (!downloadId) {
      window.alert('Please enter a file ID');
      return;
    }
    await handleDownload(downloadId);
    setDownloadId('');
  };

  const handleDelete = async (fileId: string) => {
    if (!window.confirm('Are you sure you want to delete this file?')) {
      return;
    }
    
    try {
      const response = await fetch(`${API_BASE}/delete/${fileId}`, {
        method: 'DELETE',
      });
      
      if (response.ok) {
        window.alert('File deleted successfully');
        fetchFiles();
      } else {
        window.alert('Delete failed');
      }
    } catch (error) {
      window.alert('Delete error');
      console.error('Error:', error);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>File Transfer Server</h1>
        
        <div className="upload-section">
          <h2>Upload</h2>
          <div>
            <input
              type="file"
              onChange={(e) => setSelectedFile(e.target.files?.[0] || null)}
            />
          </div>
          <div>
            <textarea
              placeholder="Or enter text to upload"
              value={textContent}
              onChange={(e) => setTextContent(e.target.value)}
              rows={4}
              cols={50}
            />
          </div>
          <button onClick={handleFileUpload}>Upload</button>
          {uploadStatus && <p>{uploadStatus}</p>}
        </div>

        <div className="download-section">
          <h2>Download by ID</h2>
          <input
            type="text"
            placeholder="Enter file ID"
            value={downloadId}
            onChange={(e) => setDownloadId(e.target.value)}
          />
          <button onClick={handleDownloadById}>Download</button>
        </div>

        <div className="files-section">
          <h2>Available Files</h2>
          <button onClick={fetchFiles}>Refresh</button>
          {files.length === 0 ? (
            <p>No files available</p>
          ) : (
            <ul>
              {files.map((file) => (
                <li key={file.file_id}>
                  <span>{file.filename} ({file.size} bytes)</span>
                  <button onClick={() => handleDownload(file.file_id, file.filename)}>
                    Download
                  </button>
                  <button onClick={() => handleDelete(file.file_id)} style={{marginLeft: '10px', backgroundColor: '#ff4444'}}>
                    Delete
                  </button>
                  <span className="file-id">ID: {file.file_id}</span>
                </li>
              ))}
            </ul>
          )}
        </div>
      </header>
    </div>
  );
}

export default App;
