#!/bin/bash
# Development server runner for File Transfer Server
# Starts both backend (FastAPI) and frontend (React) servers simultaneously

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to cleanup processes on exit
cleanup() {
    echo -e "\n${YELLOW}🛑 Stopping servers...${NC}"
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null
    fi
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null
    fi
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

echo -e "${BLUE}🚀 Starting File Transfer Server (Development Mode)${NC}"
echo "=================================================="

# Check if frontend directory exists
if [ ! -d "frontend" ]; then
    echo -e "${RED}❌ Frontend directory not found!${NC}"
    exit 1
fi

# Start backend server
echo -e "${GREEN}🚀 Starting backend server on http://localhost:8000${NC}"
python3 main.py &
BACKEND_PID=$!

# Give backend time to start
sleep 2

# Start frontend server
echo -e "${GREEN}🚀 Starting frontend server on http://localhost:3000${NC}"
cd frontend
npm start &
FRONTEND_PID=$!
cd ..

# Wait a moment for servers to initialize
sleep 3

echo ""
echo -e "${GREEN}✅ Both servers are running!${NC}"
echo "📱 Frontend: http://localhost:3000"
echo "🔗 Backend API: http://localhost:8000"
echo "📚 API Docs: http://localhost:8000/docs"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop both servers${NC}"

# Wait for processes to finish
wait $BACKEND_PID $FRONTEND_PID