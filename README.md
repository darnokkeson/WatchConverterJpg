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

Now copy a JPG or PNG image into the folder. The script will:
- Convert PNGs to JPEG format (saved to OUTPUT folder, original PNG kept)
- Create multiple optimized versions of JPG images at different file sizes: 300kB, 250kB, 200kB, 150kB, 120kB, 100kB, and 80kB
- Save all created files in the `OUTPUT/` folder automatically created in the working directory
- Keep original files intact

Example:
- Original image: `photo.jpg` (967 kB)
- Created optimized versions in OUTPUT folder:
  - `photo_300kb.jpg` (300 kB)
  - `photo_250kb.jpg` (250 kB)
  - `photo_200kb.jpg` (200 kB)
  - `photo_150kb.jpg` (150 kB)
  - `photo_120kb.jpg` (120 kB)
  - `photo_100kb.jpg` (100 kB)
  - `photo_80kb.jpg` (80 kB)
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

- Images are automatically converted (PNG to JPG) and optimized
- Multiple optimized versions are created for each image (300, 250, 200, 150, 120, 100, and 80 kB)
- All created files are automatically saved in the `OUTPUT/` folder
- Original files are preserved and never deleted
- Runs silently via systemd
- Saves significant disk space with multiple size options
- Optional monochrome conversion included

Thanks!

