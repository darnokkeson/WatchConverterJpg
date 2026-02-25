# Auto Image Optimizer for Ubuntu

Automatically monitors a folder, converts incoming PNGs to JPEG, and creates multiple optimized versions — all running silently in the background via **systemd**.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [systemd Service Setup](#systemd-service-setup)
- [Managing the Service](#managing-the-service)
- [Bonus: Monochrome Converter](#bonus-monochrome-converter)
- [License](#license)

---

## Overview

This project solves a simple problem: **reducing disk space used by images on a server without visible quality loss**.

Drop any JPG or PNG into the monitored folder and get back multiple optimized versions at different file sizes — automatically, with no manual steps.

---

## Features

- Monitors a folder in real time using `inotifywait`
- Converts PNG files to JPEG automatically
- Creates 7 optimized versions of each image (300, 250, 200, 150, 120, 100, and 80 kB)
- Saves all output to an `OUTPUT/` subfolder
- Never deletes original files
- Runs automatically on boot via `systemd`
- Bonus script for black & white conversion

---

## Requirements

| Tool | Purpose |
|------|---------|
| `inotify-tools` | Detects new files added to the folder |
| `jpegoptim` | Optimizes JPEG images without visible quality loss |
| `imagemagick` | Converts PNG files to JPEG |

---

## Installation

### 1. Install dependencies

```bash
sudo apt install inotify-tools jpegoptim imagemagick
```

### 2. Create the working directory

```bash
mkdir ~/Pictures/Converter
cd ~/Pictures/Converter
```

### 3. Download the script

```bash
nano watch_convert_jpg.sh
```

Paste the script content (see [`watch_convert_jpg.sh`](watch_convert_jpg.sh)), then make it executable:

```bash
chmod +x watch_convert_jpg.sh
```

---

## Usage

### Run manually

```bash
./watch_convert_jpg.sh
```

Drop any `.jpg` or `.png` file into the folder. The script will handle everything automatically.

### Example output

Given `photo.jpg` (967 kB), the script produces:

```
OUTPUT/
├── photo_300kb.jpg   (300 kB)
├── photo_250kb.jpg   (250 kB)
├── photo_200kb.jpg   (200 kB)
├── photo_150kb.jpg   (150 kB)
├── photo_120kb.jpg   (120 kB)
├── photo_100kb.jpg   (100 kB)
└── photo_80kb.jpg    (80 kB)
```

> Original `photo.jpg` is kept intact. Visual quality difference is not noticeable.

---

## How It Works

```

1. `inotifywait` watches for `create` and `moved_to` events
2. PNG files are converted to JPG using `convert` (ImageMagick)
3. Each JPG is copied and optimized to 7 target sizes using `jpegoptim`
4. All output files land in the `OUTPUT/` subfolder
5. Original files are never touched

---

## systemd Service Setup

To run the script automatically on boot:

### 1. Create the service file

```bash
sudo nano /etc/systemd/system/image-monitor.service
```

Paste the following — **replace `noise` with your actual username and update the paths**:

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

### 2. Enable and start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable image-monitor.service
sudo systemctl start image-monitor.service
```

---

## Managing the Service

| Action | Command |
|--------|---------|
| Check status | `sudo systemctl status image-monitor.service` |
| Stop | `sudo systemctl stop image-monitor.service` |
| Restart | `sudo systemctl restart image-monitor.service` |
| View live logs | `journalctl -u image-monitor.service -f` |

---

## Bonus: Monochrome Converter

A simple standalone script to convert any image to black and white.

### Setup

```bash
nano toMonochrome.sh
chmod +x toMonochrome.sh
```

Paste the script content (see [`toMonochrome.sh`](toMonochrome.sh)).

### Usage

```bash
# Single file
./toMonochrome.sh photo.jpg

# Multiple files
./toMonochrome.sh photo1.jpg photo2.png photo3.jpg
```

Output is saved as `photo_monochrome.jpg` alongside the original.

---

## Project Structure

```
Converter/
├── watch_convert_jpg.sh   # Main monitoring and optimization script
├── toMonochrome.sh        # Bonus: black & white converter
└── OUTPUT/                # Auto-created; all optimized files land here
```

---

## License

MIT — feel free to use, modify, and share.
