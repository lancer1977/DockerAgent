#!/bin/bash

# Specify the directory containing the scripts
script_directory="./scripts"

# Check if the directory exists
if [ -d "$script_directory" ]; then
    # Loop through all executable files in the directory
    for script_file in "$script_directory"/*; do
        # Check if the file is executable
        if [ -x "$script_file" ]; then
            # Run the script
            echo "Running script: $script_file"
            "$script_file"
        else
            echo "Skipping non-executable file: $script_file"
        fi
    done
else
    echo "Error: Directory not found - $script_directory"
fi
