#!/bin/bash
set -e

script_directory="/scripts"

if [ -d "$script_directory" ]; then
  for script_file in "$script_directory"/*; do
    [ -e "$script_file" ] || continue

    if [ -x "$script_file" ]; then
      echo "Running script: $script_file"
      "$script_file"
    else
      echo "Skipping non-executable file: $script_file"
    fi
  done
else
  echo "Error: Directory not found - $script_directory"
fi
