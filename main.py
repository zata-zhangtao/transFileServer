from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
import os
import shutil
import urllib.parse
import uuid
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

CHUNKS_DIR = Path("chunks")
CHUNKS_DIR.mkdir(exist_ok=True)

BASE_DIR = Path(__file__).resolve().parent
FRONTEND_BUILD_DIR = BASE_DIR / "frontend_build"
FRONTEND_STATIC_DIR = FRONTEND_BUILD_DIR / "static"
FRONTEND_INDEX_FILE = FRONTEND_BUILD_DIR / "index.html"

if FRONTEND_STATIC_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(FRONTEND_STATIC_DIR)), name="static")


@app.get("/healthz")
async def healthcheck():
    return {"status": "ok"}


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

    file_path = UPLOAD_DIR / f"{file_id}.txt"
    with open(file_path, "w") as f:
        f.write(text)
    return {"file_id": file_id, "filename": f"{file_id}.txt", "type": "text"}


@app.post("/upload-chunk")
async def upload_chunk(
    file_id: str = Form(...),
    chunk_index: int = Form(...),
    total_chunks: int = Form(...),
    filename: str = Form(...),
    chunk: UploadFile = File(...),
):
    """Upload a single chunk of a large file."""
    try:
        file_chunks_dir = CHUNKS_DIR / file_id
        file_chunks_dir.mkdir(exist_ok=True)

        chunk_path = file_chunks_dir / f"chunk_{chunk_index:06d}"
        with open(chunk_path, "wb") as buffer:
            shutil.copyfileobj(chunk.file, buffer)

        uploaded_chunks = len(list(file_chunks_dir.glob("chunk_*")))

        if uploaded_chunks == total_chunks:
            final_path = UPLOAD_DIR / f"{file_id}_{filename}"

            with open(final_path, "wb") as final_file:
                for i in range(total_chunks):
                    part = file_chunks_dir / f"chunk_{i:06d}"
                    if part.exists():
                        with open(part, "rb") as chunk_file:
                            shutil.copyfileobj(chunk_file, final_file)

            shutil.rmtree(file_chunks_dir)

            return {
                "file_id": file_id,
                "filename": filename,
                "type": "file",
                "status": "completed",
                "uploaded_chunks": uploaded_chunks,
                "total_chunks": total_chunks,
            }

        return {
            "file_id": file_id,
            "filename": filename,
            "type": "file",
            "status": "uploading",
            "uploaded_chunks": uploaded_chunks,
            "total_chunks": total_chunks,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chunk upload failed: {str(e)}")


@app.get("/upload-status/{file_id}")
async def get_upload_status(file_id: str):
    """Get the status of a chunked upload."""
    file_chunks_dir = CHUNKS_DIR / file_id

    if not file_chunks_dir.exists():
        matching_files = list(UPLOAD_DIR.glob(f"{file_id}*"))
        if matching_files:
            return {"status": "completed", "file_exists": True}
        return {"status": "not_found", "file_exists": False}

    uploaded_chunks = len(list(file_chunks_dir.glob("chunk_*")))

    return {
        "status": "uploading",
        "uploaded_chunks": uploaded_chunks,
        "file_exists": False,
    }


@app.get("/download/{file_id}")
async def download_file(file_id: str):
    matching_files = list(UPLOAD_DIR.glob(f"{file_id}*"))

    if not matching_files:
        raise HTTPException(status_code=404, detail="File not found")

    file_path = matching_files[0]
    filename = file_path.name.split("_", 1)[-1] if "_" in file_path.name else file_path.name
    file_size = file_path.stat().st_size

    encoded_filename = urllib.parse.quote(filename, safe="")
    content_disposition = f"attachment; filename*=UTF-8''{encoded_filename}"

    return FileResponse(
        path=file_path,
        filename=filename,
        media_type="application/octet-stream",
        headers={
            "Content-Disposition": content_disposition,
            "Content-Length": str(file_size),
            "Accept-Ranges": "bytes",
        },
    )


@app.get("/files")
async def list_files():
    files = []
    for file_path in UPLOAD_DIR.glob("*"):
        if file_path.is_file():
            file_id = file_path.stem.split("_")[0]
            filename = file_path.name.split("_", 1)[-1] if "_" in file_path.name else file_path.name
            files.append(
                {
                    "file_id": file_id,
                    "filename": filename,
                    "size": file_path.stat().st_size,
                }
            )
    return {"files": files}


@app.delete("/delete/{file_id}")
async def delete_file(file_id: str):
    matching_files = list(UPLOAD_DIR.glob(f"{file_id}*"))

    if not matching_files:
        raise HTTPException(status_code=404, detail="File not found")

    file_path = matching_files[0]

    try:
        file_path.unlink()
        return {"message": "File deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting file: {str(e)}")


def _is_reserved_path(path: str) -> bool:
    reserved_prefixes = (
        "upload",
        "upload-chunk",
        "upload-status",
        "download",
        "files",
        "delete",
        "healthz",
        "docs",
        "redoc",
        "openapi.json",
        "relay",
        "static",
    )

    normalized = path.lstrip("/")
    return any(
        normalized == prefix or normalized.startswith(f"{prefix}/")
        for prefix in reserved_prefixes
    )


@app.get("/", include_in_schema=False)
async def serve_index():
    if FRONTEND_INDEX_FILE.exists():
        return FileResponse(FRONTEND_INDEX_FILE)

    return JSONResponse(
        {
            "service": "File Transfer Server",
            "status": "running",
            "docs": "/docs",
            "frontend": "frontend build not found in current runtime",
        }
    )


@app.get("/{full_path:path}", include_in_schema=False)
async def spa_fallback(full_path: str):
    if _is_reserved_path(full_path):
        raise HTTPException(status_code=404, detail="Not found")

    if FRONTEND_INDEX_FILE.exists():
        return FileResponse(FRONTEND_INDEX_FILE)

    raise HTTPException(status_code=404, detail="Not found")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
