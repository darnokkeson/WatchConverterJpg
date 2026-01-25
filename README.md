markdown

# Image Optimization and Automation on Ubuntu

To save space on expensive server storage, you can downsize pictures to the smallest size possible using an automated script managed by `systemd`.

## 1. Install Required Software
Install `inotify-tools` to detect new files and `jpegoptim` for image compression.

```bash
sudo apt update
sudo apt install inotify-tools jpegoptim -y

Używaj kodu z rozwagą.
2. Setup the Converter Script
Create a directory for the script and the images, then create the script file.
bash

mkdir -p ~/Pictures/Converter
cd ~/Pictures/Converter
nano watch_convert_jpg.sh

Używaj kodu z rozwagą.
Paste the following code:
bash

#!/bin/bash

# Folder to monitor
TARGET_DIR="."
# Size limit: 350 kB in bytes
SIZE_LIMIT=358400

# Enter the directory
cd "$TARGET_DIR" || exit

echo "Monitoring for new JPGs in $(pwd)..."

# Monitor for 'create' and 'moved_to' events
inotifywait -m -e create -e moved_to --format "%f" . | while read FILENAME
do
    # Check for jpg extension
    if [[ "$FILENAME" =~ \.(jpg|jpeg|JPG|JPEG)$ ]]; then

        # Wait a moment to ensure the file is fully written
        sleep 1

        # Get file size in bytes
        FILE_SIZE=$(stat -c%s "$FILENAME")

        if [ "$FILE_SIZE" -gt "$SIZE_LIMIT" ]; then
            echo "Optimization triggered: $FILENAME ($FILE_SIZE bytes)"
            # Downsize to target size
            jpegoptim --size=300k "$FILENAME"
        fi
    fi
done

Używaj kodu z rozwagą.
Make the script executable:
bash

chmod +x watch_convert_jpg.sh

Używaj kodu z rozwagą.
3. Configure systemd Service
Create a service file to ensure the script starts automatically on boot.
bash

sudo nano /etc/systemd/system/image-monitor.service

Używaj kodu z rozwagą.
Paste the following configuration (Replace noise with your actual username):
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
bash

# Reload daemon
sudo systemctl daemon-reload

# Enable on boot
sudo systemctl enable image-monitor.service

# Start now
sudo systemctl start image-monitor.service

Używaj kodu z rozwagą.
Management Commands

    Check status: sudo systemctl status image-monitor.service
    View logs: journalctl -u image-monitor.service -f

Extra: Monochrome Conversion
To convert color images (like paper drawings) to digital-style black and white, install ImageMagick:
bash

sudo apt install imagemagick -y

Używaj kodu z rozwagą.
Create toMonochrome.sh:
bash

#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./toMonochrome.sh image.jpg"
    exit 1
fi

for input_file in "$@"; do
    filename="${input_file%.*}"
    extension="${input_file##*.}"
    output_file="${filename}_monochrome.${extension}"

    echo "Converting $input_file to $output_file..."
    convert "$input_file" -monochrome "$output_file"
done

echo "Done!"

Używaj kodu z rozwagą.
Run it:
bash

chmod +x toMonochrome.sh
./toMonochrome.sh pictureName.jpg

