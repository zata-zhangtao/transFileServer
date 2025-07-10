#!/usr/bin/env python3
"""
Development server runner for File Transfer Server
Starts both backend (FastAPI) and frontend (React) servers simultaneously
"""

import subprocess
import sys
import os
import signal
import time
from pathlib import Path

def run_backend():
    """Run the FastAPI backend server"""
    print("🚀 Starting backend server on http://localhost:8000")
    return subprocess.Popen([
        sys.executable, "main.py"
    ], cwd=".")

def run_frontend():
    """Run the React frontend server"""
    frontend_dir = Path("frontend")
    if not frontend_dir.exists():
        print("❌ Frontend directory not found!")
        return None
    
    print("🚀 Starting frontend server on http://localhost:3000")
    return subprocess.Popen([
        "npm", "start"
    ], cwd=frontend_dir)

def main():
    processes = []
    
    try:
        # Start backend server
        backend_process = run_backend()
        if backend_process:
            processes.append(backend_process)
            time.sleep(2)  # Give backend time to start
        
        # Start frontend server
        frontend_process = run_frontend()
        if frontend_process:
            processes.append(frontend_process)
        
        if not processes:
            print("❌ No servers started!")
            return
        
        print("\n✅ Both servers are starting!")
        print("📱 Frontend: http://localhost:3000")
        print("🔗 Backend API: http://localhost:8000")
        print("📚 API Docs: http://localhost:8000/docs")
        print("\nPress Ctrl+C to stop both servers")
        
        # Wait for processes
        for process in processes:
            process.wait()
            
    except KeyboardInterrupt:
        print("\n🛑 Stopping servers...")
        for process in processes:
            process.terminate()
        
        # Wait a bit for graceful shutdown
        time.sleep(1)
        
        # Force kill if still running
        for process in processes:
            if process.poll() is None:
                process.kill()
        
        print("✅ Servers stopped")

if __name__ == "__main__":
    main()