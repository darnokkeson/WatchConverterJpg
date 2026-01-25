To save space on expensive server storage, I need to downsize my pictures to the smallest size possible. To do this, I created a script which is automatically started by systemd in Ubuntu Linux.

To do this, we need to install some new software.

Install inotifywait to detect new pictures in the folder. This will be used in the script.

sudo apt install inotify-tools

sudo apt install inotify-tools
Install jpegoptim for downsizing pictures without a visible change in quality.

sudo apt install jpegoptim

sudo apt install jpegoptim
Create a new directory in the Pictures folder.

mkdir Converter

mkdir Converter
Create a new .sh file in the new folder.

nano watch_convert_jpg.sh

nano watch_convert_jpg.sh
Paste this code there:

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
Make it executable:

chmod +x watch_convert_jpg.sh

chmod +x watch_convert_jpg.sh
Now you can test this script by running it in the terminal:

./watch_convert_jpg.sh

./watch_convert_jpg.sh
I put this picture, which is 967 kB, into the folder with the script.


Now the new picture is 299 kB and looks like the original, but it is 3 times lighter.


The answer is one.


If everything is okay, you can proceed to the next step.

Next, we need to enable the autostart of this script automatically after the OS boots. Create a new service file:

sudo nano /etc/systemd/system/image-monitor.service

sudo nano /etc/systemd/system/image-monitor.service
Paste this code and replace the actual paths and Username:

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
Enable and Start the Service. Run these commands to tell the system to load the new service and start it immediately.

Reload the daemon:

sudo systemctl daemon-reload

sudo systemctl daemon-reload
Enable on boot:

sudo systemctl enable image-monitor.service

sudo systemctl enable image-monitor.service
Restart the system and check if the script is running automatically in the background. After the restart, we can monitor our script.

Check status to see if it is currently running:

sudo systemctl status image-monitor.service

sudo systemctl status image-monitor.service
Stop it (do not do this unless you want to disable the service permanently):

sudo systemctl stop image-monitor.service

sudo systemctl stop image-monitor.service
View logs:

journalctl -u image-monitor.service -f

journalctl -u image-monitor.service -f
EXTRA SCRIPT

Sometimes I need to change a color picture to black and white only. Install ImageMagick to do that. ImageMagick is called in the code by the convert command.

sudo apt install imagemagick

sudo apt install imagemagick
I can do it by using the toMonochrome.sh script:

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
Run it using this command:

./toMonochrome.sh pictureName.jpg

./toMonochrome.sh pictureName.jpg

but more usable is running this script on pictures like this:


This drawing was created on paper. Thanks to my script, it looks like it was done digitally.

That’s all.

Thanks!
