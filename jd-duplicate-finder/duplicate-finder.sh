#!/usr/local/bin/bash

mypwd=`pwd`
current_folder="."
other_folder="$1"

# Check if the other folder argument is provided
if [ -z "$other_folder" ]; then
  echo "Usage: $0 <other_folder>"
  exit 1
fi

# Function to recursively search for duplicated files
search_duplicates() {
  local current_file="$1"
  local other_path="$2"
  
  for file in "$other_path"/*; do
    if [ -f "$file" ]; then
      if cmp -s "$current_file" "$file"; then
        echo "File '$current_file' is duplicated in '$other_path'."
      fi
    elif [ -d "$file" ]; then
      search_duplicates "$current_file" "$file"
    fi
  done
}

# Loop through files in the current folder
for file in "$current_folder"/*; do
  if [ -f "$file" ]; then
    # Extract the filename
    filename=$(basename "$file")
  
    # Perform recursive search in the other folder
    search_duplicates "$file" "$other_folder"
  fi
done

