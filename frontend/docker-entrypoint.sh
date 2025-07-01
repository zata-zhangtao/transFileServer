#!/bin/sh
set -e

echo "=== Frontend Container Starting ==="
echo "REACT_APP_API_URL: $REACT_APP_API_URL"

# List JavaScript files for debugging
echo "=== JavaScript files found ==="
find /usr/share/nginx/html -name "*.js" -type f | head -10

# Replace environment variables in JavaScript files
if [ -n "$REACT_APP_API_URL" ]; then
  echo "=== Replacing API URL with: $REACT_APP_API_URL ==="
  
  # Check if localhost:8000 exists in any JS files before replacement
  echo "=== Checking for localhost:8000 in JS files ==="
  if find /usr/share/nginx/html -name "*.js" -type f -exec grep -l "localhost:8000" {} \; | head -5; then
    echo "Found localhost:8000 in JS files, proceeding with replacement"
  else
    echo "No localhost:8000 found in JS files"
  fi
  
  # Replace various forms of localhost:8000 that might appear in the built files
  find /usr/share/nginx/html -name "*.js" -type f -exec sed -i \
    -e "s|http://localhost:8000|$REACT_APP_API_URL|g" \
    -e "s|\"http://localhost:8000\"|\"$REACT_APP_API_URL\"|g" \
    -e "s|'http://localhost:8000'|'$REACT_APP_API_URL'|g" \
    -e "s|http:\\/\\/localhost:8000|$REACT_APP_API_URL|g" \
    {} \;
  
  # Also check static/js directory specifically
  if [ -d "/usr/share/nginx/html/static/js" ]; then
    find /usr/share/nginx/html/static/js -name "*.js" -type f -exec sed -i \
      -e "s|http://localhost:8000|$REACT_APP_API_URL|g" \
      -e "s|\"http://localhost:8000\"|\"$REACT_APP_API_URL\"|g" \
      -e "s|'http://localhost:8000'|'$REACT_APP_API_URL'|g" \
      -e "s|http:\\/\\/localhost:8000|$REACT_APP_API_URL|g" \
      {} \;
  fi
  
  # Verify replacement was successful
  echo "=== Verifying replacement ==="
  if find /usr/share/nginx/html -name "*.js" -type f -exec grep -l "$REACT_APP_API_URL" {} \; | head -3; then
    echo "✅ Successfully found new API URL in JS files"
  else
    echo "❌ New API URL not found in JS files"
  fi
  
  echo "=== URL replacement completed ==="
else
  echo "REACT_APP_API_URL not set, using default: http://localhost:8000"
fi

echo "=== Starting nginx ==="
# Start nginx
exec nginx -g "daemon off;" 