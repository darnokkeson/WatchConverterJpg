#!/bin/bash
# Folder to monitor
TARGET_DIR="."
# Size limit: 350 kB in bytes
SIZE_LIMIT=358400
# Enter the directory so we can work with just the filename
cd "$TARGET_DIR" || exit
echo "Monitoring for new JPGs and PNGs in $(pwd)..."
# Monitor for 'create' and 'moved_to' events
inotifywait -m -e create -e moved_to --format "%f" . | while read FILENAME
do
    # --- PNG to JPG conversion ---
    if [[ "$FILENAME" =~ \.(png|PNG)$ ]]; then
        sleep 1
        JPG_FILENAME="${FILENAME%.*}.jpg"
        echo "Converting PNG to JPG: $FILENAME -> $JPG_FILENAME"
        convert "$FILENAME" "$JPG_FILENAME"
        if [ $? -eq 0 ]; then
            rm "$FILENAME"
            echo "Removed original PNG: $FILENAME"
            FILENAME="$JPG_FILENAME"
        else
            echo "Conversion failed for: $FILENAME"
            continue
        fi
    fi

    # --- JPG optimization ---
    if [[ "$FILENAME" =~ \.(jpg|jpeg|JPG|JPEG)$ ]]; then
        sleep 1
        FILE_SIZE=$(stat -c%s "$FILENAME")
        if [ "$FILE_SIZE" -gt "$SIZE_LIMIT" ]; then
            echo "Optimization triggered: $FILENAME ($FILE_SIZE bytes)"
            jpegoptim --size=300k "$FILENAME"
        fi
    fi
done
