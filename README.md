# Auto Image Optimizer and Monochrome Converter for Ubuntu

To save space on expensive server storage, this guide explains how to downsize pictures to the smallest size possible using an automated script managed by `systemd`.

## 1. Prerequisites
Install `inotify-tools` to detect new files and `jpegoptim` for image compression.

```bash
sudo apt update
sudo apt install inotify-tools jpegoptim -y

2. Create the Monitoring Script
Create a new directory and the shell script that will watch for new images.
bash

mkdir -p ~/Pictures/Converter
cd ~/Pictures/Converter
nano watch_convert_jpg.sh

Paste the following code into the editor:
bash

#!/bin/bash

# Folder to monitor (current directory)
TARGET_DIR="."
# Size limit: ~350 kB in bytes
SIZE_LIMIT=358400

# Enter the directory
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

            # Use jpegoptim to downsize to approximately 300k
            jpegoptim --size=300k "$FILENAME"
        fi
    fi
done

Make the script executable:
bash

chmod +x watch_convert_jpg.sh

3. Automate with systemd
Create a service file to ensure the script runs in the background automatically after the OS boots.
bash

sudo nano /etc/systemd/system/image-monitor.service

Używaj kodu z rozwagą.
Paste the following code (replace noise with your actual Ubuntu username and verify paths):
ini

[Unit]
Description=Auto Detect and Optimize JPG Files
After=network.target

[Service]
ExecStart=/bin/bash /home/noise/Pictures/Converter/watch_convert_jpg.sh
WorkingDirectory=/home/noise/Pictures/Converter
User=noise
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target

Używaj kodu z rozwagą.
4. Enable and Start the Service
Run these commands to load the new service and start it immediately.
bash

# Reload the daemon
sudo systemctl daemon-reload

# Enable on boot
sudo systemctl enable image-monitor.service

# Start the service
sudo systemctl start image-monitor.service

Używaj kodu z rozwagą.
Monitoring the Service

    Check status: sudo systemctl status image-monitor.service
    View live logs: journalctl -u image-monitor.service -f
    Stop service: sudo systemctl stop image-monitor.service

EXTRA: Monochrome Conversion Script
Sometimes it is useful to change a color drawing (on paper) to a clean black and white digital-style image.
Install ImageMagick
bash

sudo apt install imagemagick -y

Używaj kodu z rozwagą.
Create the Monochrome Script
bash

nano toMonochrome.sh

Używaj kodu z rozwagą.
Paste the following code:
bash

#!/bin/bash

# Check if a file was provided
if [ -z "$1" ]; then
    echo "Usage: ./toMonochrome.sh image.jpg"
    exit 1
fi

# Loop through all files passed as arguments
for input_file in "$@"; do
    # Get the filename without the extension
    filename="${input_file%.*}"
    # Get the extension
    extension="${input_file##*.}"
    
    # Define the new name
    output_file="${filename}_monochrome.${extension}"

    echo "Converting $input_file to $output_file..."
    
    # Convert to grayscale using ImageMagick
    convert "$input_file" -monochrome "$output_file"
done

echo "Done!"

Używaj kodu z rozwagą.
Usage
Make it executable and run it on any image:
bash

chmod +x toMonochrome.sh
