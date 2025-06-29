# File Transfer Server

A simple file transfer server that allows you to upload files or text from one computer and download them from another using unique file IDs.

## Features

- Upload files or text content
- Download files using unique IDs
- List all available files
- React frontend with clean UI
- FastAPI backend with CORS enabled

## Setup

### Backend (FastAPI)

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Run the server:
```bash
python main.py
```

The API will be available at `http://localhost:8000`

### Frontend (React)

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm start
```

The frontend will be available at `http://localhost:3000`

## Usage

1. **Upload**: Select a file or enter text content and click "Upload"
2. **Download by ID**: Enter a file ID and click "Download"
3. **Browse Files**: View all available files and download them directly

## API Endpoints

- `POST /upload` - Upload a file or text
- `GET /download/{file_id}` - Download a file by ID
- `GET /files` - List all available files

Files are stored in the `uploads/` directory on the server.