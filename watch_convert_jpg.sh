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
        # Create OUTPUT folder if it doesn't exist
        mkdir -p OUTPUT
        JPG_FILENAME="${FILENAME%.*}.jpg"
        echo "Converting PNG to JPG: $FILENAME -> $JPG_FILENAME"
        convert "$FILENAME" "OUTPUT/$JPG_FILENAME"
        if [ $? -eq 0 ]; then
            echo "Original PNG kept: $FILENAME"
            FILENAME="OUTPUT/$JPG_FILENAME"
        else
            echo "Conversion failed for: $FILENAME"
            continue
        fi
    fi

    # --- JPG optimization with different file sizes ---
    if [[ "$FILENAME" =~ \.(jpg|jpeg|JPG|JPEG)$ ]]; then
        sleep 1
        # Create OUTPUT folder if it doesn't exist
        mkdir -p OUTPUT
        
        # Get just the filename without path
        BASE_FILENAME=$(basename "$FILENAME")
        
        # Define file sizes in kB for optimized versions
        SIZES=(300 250 200 150 120 100 80)
        
        echo "Creating optimized versions of: $BASE_FILENAME"
        
        # Create optimized versions for each file size
        for SIZE in "${SIZES[@]}"; do
            OUTPUT_FILENAME="${BASE_FILENAME%.*}_${SIZE}kb.jpg"
            echo "  Optimizing to ${SIZE}kB: $OUTPUT_FILENAME"
            # Copy original to OUTPUT folder and optimize
            cp "$FILENAME" "OUTPUT/$OUTPUT_FILENAME"
            jpegoptim --size=${SIZE}k "OUTPUT/$OUTPUT_FILENAME"
            if [ $? -eq 0 ]; then
                echo "  Created: OUTPUT/$OUTPUT_FILENAME"
            else
                echo "  Failed to optimize: $OUTPUT_FILENAME"
            fi
        done
        
        echo "Optimization complete. Original file kept: $BASE_FILENAME"
    fi
done
