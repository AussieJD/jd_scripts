#!/bin/bash

# Function to display the menu
display_menu() {
  clear
  echo "Numbered Menu"
  echo "------------"
  local index=1
  for file in *; do
    if [[ -f "$file" ]]; then
      echo "$index. $file"
      ((index++))
    fi
  done
  echo "0. Exit"
}

# Function to delete a file
delete_file() {
  local file_index=$1
  local file_name=$(ls | grep -v '\.$' | sed -n "${file_index}p")
  if [[ -n "$file_name" ]]; then
    rm "$file_name"
    echo "File '$file_name' deleted."
  fi
}

# Main script logic
while true; do
  display_menu

  read -p "Enter the number of the file to delete (0 to exit): " choice
  if [[ $choice -eq 0 ]]; then
    echo "Exiting..."
    break
  fi

  local index=1
  local selected_file=""
  for file in *; do
    if [[ -f "$file" ]]; then
      if [[ $index -eq $choice ]]; then
        selected_file="$file"
        break
      fi
      ((index++))
    fi
  done

  if [[ -n "$selected_file" ]]; then
    delete_file "$selected_file"
    read -n 1 -s -r -p "Press any key to continue..."
  else
    echo "Invalid choice. Please try again."
    read -n 1 -s -r -p "Press any key to continue..."
  fi
done

