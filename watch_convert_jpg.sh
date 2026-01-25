#!/bin/bash

# Folder to monitor
TARGET_DIR="."
# Size limit: 350 kB in bytes
SIZE_LIMIT=358400

# Enter the directory so we can work with just the filename
cd "$TARGET_DIR" || exit

echo "Monitoring for new JPGs in $(pwd)..."

# Monitor for 'create' and 'moved_to' events
inotifywait -m -e create -e moved_to --format "%f" . | while read FILENAME
do
    # Check for jpg extension
    if [[ "$FILENAME" =~ \.(jpg|jpeg|JPG|JPEG)$ ]]; then
        
        # Wait a moment to ensure the file is fully copied/written
        sleep 1
        
        # Get file size in bytes
        FILE_SIZE=$(stat -c%s "$FILENAME")

        if [ "$FILE_SIZE" -gt "$SIZE_LIMIT" ]; then
            echo "Optimization triggered: $FILENAME ($FILE_SIZE bytes)"
            
            # Use only the filename as requested
            jpegoptim --size=300k "$FILENAME"
        fi
    fi
done
