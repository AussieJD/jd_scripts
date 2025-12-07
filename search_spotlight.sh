#!/usr/local/bin/bash

# Function to search for a file using Spotlight
search_spotlight() {
    local query="$1"
    mdfind "kMDItemDisplayName == '$query'"
}

# Prompt the user for a file name to search for
read -p "Enter a file name to search for: " file_name

# Call the search_spotlight function with the provided file name
search_spotlight "$file_name"

