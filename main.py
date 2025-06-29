from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import os
import uuid
import shutil
from pathlib import Path

app = FastAPI(title="File Transfer Server")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

@app.post("/upload")
async def upload_file(file: UploadFile = File(None), text: str = Form(None)):
    if not file and not text:
        raise HTTPException(status_code=400, detail="Either file or text must be provided")
    
    file_id = str(uuid.uuid4())
    
    if file:
        file_path = UPLOAD_DIR / f"{file_id}_{file.filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        return {"file_id": file_id, "filename": file.filename, "type": "file"}
    else:
        file_path = UPLOAD_DIR / f"{file_id}.txt"
        with open(file_path, "w") as f:
            f.write(text)
        return {"file_id": file_id, "filename": f"{file_id}.txt", "type": "text"}

@app.get("/download/{file_id}")
async def download_file(file_id: str):
    matching_files = list(UPLOAD_DIR.glob(f"{file_id}*"))
    
    if not matching_files:
        raise HTTPException(status_code=404, detail="File not found")
    
    file_path = matching_files[0]
    filename = file_path.name.split("_", 1)[-1] if "_" in file_path.name else file_path.name
    
    return FileResponse(
        path=file_path,
        filename=filename,
        media_type='application/octet-stream'
    )

@app.get("/files")
async def list_files():
    files = []
    for file_path in UPLOAD_DIR.glob("*"):
        if file_path.is_file():
            file_id = file_path.stem.split("_")[0]
            filename = file_path.name.split("_", 1)[-1] if "_" in file_path.name else file_path.name
            files.append({
                "file_id": file_id,
                "filename": filename,
                "size": file_path.stat().st_size
            })
    return {"files": files}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)