# Automatic Image Optimization on Ubuntu Using systemd

To save space on expensive server storage, I needed to downsize my pictures to the smallest size possible **without visible quality loss**.  
To achieve this, I created a Bash script that automatically monitors a folder, converts any incoming PNGs to JPEG, and then optimizes the resulting JPEG images.  
The script is started automatically using **systemd** on Ubuntu Linux.

---

## 1. Install Required Software

### Install `inotifywait`
This tool detects new files added to a directory.

```bash
sudo apt install inotify-tools
```

### Install `jpegoptim`
This tool optimizes JPEG images without visible quality degradation.

```bash
sudo apt install jpegoptim
```

### Install `ImageMagick` (for PNG → JPG conversion)
The `convert` utility is provided by ImageMagick and is required if you want the script to convert incoming PNG files into JPEGs before optimization.

```bash
sudo apt install imagemagick
```

---

## 2. Create the Working Directory

Create a new directory inside your `Pictures` folder:

```bash
mkdir ~/Pictures/Converter
cd ~/Pictures/Converter
```

---

## 3. Create the Monitoring Script

Create a new shell script:

```bash
nano watch_convert_jpg.sh
```

Paste the following code into the file:

```bash
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
```

Make the script executable:

```bash
chmod +x watch_convert_jpg.sh
```

---

## 4. Test the Script Manually

Run the script:

```bash
./watch_convert_jpg.sh
```

Now copy a JPG or PNG image into the folder. PNGs will be converted to JPEG before optimization.

Example:
- Original size: 967 kB  
- Optimized size: 299 kB  
- Visual quality: No noticeable difference  

---

## 5. Create a systemd Service for Autostart

Create a new service file:

```bash
sudo nano /etc/systemd/system/image-monitor.service
```

Paste the following content and replace paths and username:

```ini
[Unit]
Description=Auto Detect, Convert PNG to JPG and Optimize Images
After=network.target

[Service]
ExecStart=/bin/bash /home/noise/Pictures/Converter/watch_convert_jpg.sh
WorkingDirectory=/home/noise/Pictures/Converter
User=noise
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

---

## 6. Enable and Start the Service

Reload systemd:

```bash
sudo systemctl daemon-reload
```

Enable on boot:

```bash
sudo systemctl enable image-monitor.service
```

Start immediately:

```bash
sudo systemctl start image-monitor.service
```

---

## 7. Managing the Service

Check status:

```bash
sudo systemctl status image-monitor.service
```

Stop service:

```bash
sudo systemctl stop image-monitor.service
```

View logs:

```bash
journalctl -u image-monitor.service -f
```

---

## EXTRA SCRIPT: Convert Images to Black & White

Install ImageMagick:

```bash
sudo apt install imagemagick
```

Create the script:

```bash
nano toMonochrome.sh
```

Paste:

```bash
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
```

Make executable:

```bash
chmod +x toMonochrome.sh
```

Run:

```bash
./toMonochrome.sh pictureName.jpg
```

---

## Final Notes

- Images are optimized automatically
- Runs silently via systemd
- Saves significant disk space
- Optional monochrome conversion included

Thanks!

