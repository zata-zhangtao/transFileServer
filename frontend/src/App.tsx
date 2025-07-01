// Import React library and specific hooks we'll use
// React is the core library, useState and useEffect are "hooks" for managing state and side effects
import React, { useState, useEffect } from 'react';
// Import the CSS styles for this component
import './App.css';

// TypeScript interface definition - this defines the shape/structure of our data
// Interfaces help with type safety and code documentation
interface FileInfo {
  file_id: string;    // Each file has a unique ID (string type)
  filename: string;   // The original filename
  size: number;       // File size in bytes (number type)
}

// Main App component - this is a "functional component" (modern React style)
// Components are like custom HTML elements that can contain logic and state
function App() {
  // useState Hook - manages component state (data that can change over time)
  // Syntax: const [currentValue, setterFunction] = useState(initialValue)
  
  // State for storing the list of files from the server
  const [files, setFiles] = useState<FileInfo[]>([]);
  // <FileInfo[]> is TypeScript syntax meaning "array of FileInfo objects"
  
  // State for the currently selected file (File is a browser API type)
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  // File | null means it can be either a File object or null (no file selected)
  
  // State for text content that user types in
  const [textContent, setTextContent] = useState('');
  // Simple string state, starts as empty string
  
  // State for showing upload status messages
  const [uploadStatus, setUploadStatus] = useState('');
  
  // State for the download ID input field
  const [downloadId, setDownloadId] = useState('');

  // Environment variable for API base URL - falls back to localhost if not set
  // process.env gives access to environment variables
  const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8000';

  // Async function to fetch files from the server
  // async/await is modern JavaScript for handling asynchronous operations
  const fetchFiles = async () => {
    try {
      // fetch() is the modern way to make HTTP requests (replaces old XMLHttpRequest)
      const response = await fetch(`${API_BASE}/files`);
      // Template literal syntax: `string ${variable}` - embeds variables in strings
      
      // Convert response to JSON format
      const data = await response.json();
      
      // Update the files state with new data
      // setFiles triggers a re-render of the component
      setFiles(data.files);
    } catch (error) {
      // Handle any errors that occur during the fetch
      console.error('Error fetching files:', error);
    }
  };

  // useEffect Hook - runs side effects (code that affects things outside the component)
  // This is similar to componentDidMount in class components
  useEffect(() => {
    // This function runs after the component mounts (appears on screen)
    fetchFiles();
  }, []); // Empty dependency array [] means this only runs once when component mounts

  // Event handler function for file upload
  // async because we need to wait for the server response
  const handleFileUpload = async () => {
    // Validation - check if user provided either a file or text
    if (!selectedFile && !textContent) {
      setUploadStatus('Please select a file or enter text');
      return; // Exit early if validation fails
    }

    // FormData is a browser API for sending file uploads
    // It creates the proper format for multipart/form-data requests
    const formData = new FormData();
    
    // Add file to form data if one was selected
    if (selectedFile) {
      formData.append('file', selectedFile);
    }
    
    // Add text content if provided
    if (textContent) {
      formData.append('text', textContent);
    }

    try {
      // POST request to upload endpoint
      const response = await fetch(`${API_BASE}/upload`, {
        method: 'POST',  // HTTP method
        body: formData,  // Send the form data
      });

      // Check if request was successful
      if (response.ok) {
        const result = await response.json();
        
        // Update status with success message
        setUploadStatus(`Upload successful! File ID: ${result.file_id}`);
        
        // Reset form fields by updating state
        setSelectedFile(null);
        setTextContent('');
        
        // Refresh the files list to show the new file
        fetchFiles();
      } else {
        setUploadStatus('Upload failed');
      }
    } catch (error) {
      setUploadStatus('Upload error');
      console.error('Error:', error);
    }
  };

  // Function to handle file downloads
  // Takes fileId (required) and optional filename
  const handleDownload = async (fileId: string, filename?: string) => {
    // filename?: string means filename is optional (can be undefined)
    try {
      const response = await fetch(`${API_BASE}/download/${fileId}`);
      
      if (response.ok) {
        // Convert response to a Blob (binary large object) for file download
        const blob = await response.blob();
        
        // Create a temporary URL for the blob
        const url = window.URL.createObjectURL(blob);
        
        // Create a temporary anchor element for download
        const a = document.createElement('a');
        a.href = url;
        
        // Set download filename - use provided name, or extract from headers, or default
        a.download = filename || response.headers.get('Content-Disposition')?.split('filename=')[1] || 'download';
        
        // Trigger download by programmatically clicking the link
        document.body.appendChild(a);
        a.click();
        
        // Clean up - remove the temporary URL and element
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

  // Handler for downloading by ID (from the input field)
  const handleDownloadById = async () => {
    if (!downloadId) {
      window.alert('Please enter a file ID');
      return;
    }
    
    // Reuse the handleDownload function
    await handleDownload(downloadId);
    
    // Clear the input field
    setDownloadId('');
  };

  // Handler for deleting files
  const handleDelete = async (fileId: string) => {
    // Show confirmation dialog before deleting
    if (!window.confirm('Are you sure you want to delete this file?')) {
      return;
    }
    
    try {
      // DELETE HTTP request
      const response = await fetch(`${API_BASE}/delete/${fileId}`, {
        method: 'DELETE',
      });
      
      if (response.ok) {
        window.alert('File deleted successfully');
        fetchFiles(); // Refresh the list
      } else {
        window.alert('Delete failed');
      }
    } catch (error) {
      window.alert('Delete error');
      console.error('Error:', error);
    }
  };

  // JSX Return - this is what gets rendered to the screen
  // JSX looks like HTML but it's actually JavaScript that creates React elements
  return (
    <div className="App">
      {/* className is JSX equivalent of HTML's class attribute */}
      <header className="App-header">
        {/* JSX uses camelCase for attributes: className, onClick, etc. */}
        <h1>File Transfer Server</h1>
        
        {/* Upload Section */}
        <div className="upload-section">
          <h2>Upload</h2>
          
          {/* File input section */}
                     <div>
             {/* Event handler - onChange fires when user selects a file */}
             {/* Arrow function: (e) => ... is shorthand for function(e) { ... } */}
             {/* e.target.files?.[0] uses optional chaining (?.) to safely access files[0] */}
             <input
               type="file"
               onChange={(e) => setSelectedFile(e.target.files?.[0] || null)}
             />
           </div>
          
          {/* Text input section */}
                     <div>
             {/* Controlled component - value comes from state */}
             {/* Update state on change */}
             <textarea
               placeholder="Or enter text to upload"
               value={textContent}
               onChange={(e) => setTextContent(e.target.value)}
               rows={4}
               cols={50}
             />
           </div>
          
          {/* Upload button */}
          <button onClick={handleFileUpload}>Upload</button>
          
          {/* Conditional rendering - only show status if it exists */}
          {uploadStatus && <p>{uploadStatus}</p>}
          {/* {condition && <element>} means: if condition is true, render element */}
        </div>

        {/* Download by ID Section */}
        <div className="download-section">
          <h2>Download by ID</h2>
                     {/* Controlled input */}
           <input
             type="text"
             placeholder="Enter file ID"
             value={downloadId}
             onChange={(e) => setDownloadId(e.target.value)}
           />
          <button onClick={handleDownloadById}>Download</button>
        </div>

        {/* Files List Section */}
        <div className="files-section">
          <h2>Available Files</h2>
          <button onClick={fetchFiles}>Refresh</button>
          
          {/* Conditional rendering - show different content based on files array length */}
          {files.length === 0 ? (
            // If no files, show this message
            <p>No files available</p>
          ) : (
            // If files exist, render the list
            <ul>
              {/* Array.map() - transforms each array item into JSX */}
              {files.map((file) => (
                // Each list item needs a unique 'key' prop for React's reconciliation
                <li key={file.file_id}>
                  {/* Display file info */}
                  <span>{file.filename} ({file.size} bytes)</span>
                  
                  {/* Download button - passes file info to handler */}
                  <button onClick={() => handleDownload(file.file_id, file.filename)}>
                    Download
                  </button>
                  
                                     {/* Delete button with inline styles */}
                   {/* style prop takes an object with camelCase CSS properties */}
                   <button 
                     onClick={() => handleDelete(file.file_id)} 
                     style={{marginLeft: '10px', backgroundColor: '#ff4444'}}
                   >
                     Delete
                   </button>
                  
                  {/* File ID display */}
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

// Export the component so it can be imported in other files
export default App;
