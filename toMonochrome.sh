#!/bin/bash

# Check if a file was provided
if [ -z "$1" ]; then
    echo "Usage: ./togray.sh image.jpg"
    exit 1
fi

# Loop through all files passed as arguments
for input_file in "$@"; do
    # Get the filename without the extension (e.g., "vacation" from "vacation.jpg")
    filename="${input_file%.*}"
    # Get the extension (e.g., "jpg")
    extension="${input_file##*.}"
    
    # Define the new name
    output_file="${filename}_monochrome.${extension}"

    echo "Converting $input_file to $output_file..."
    
    # Convert to grayscale using ImageMagick
    convert "$input_file" -monochrome "$output_file"
done

echo "Done!"
