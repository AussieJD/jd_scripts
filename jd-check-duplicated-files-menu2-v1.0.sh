#!/bin/bash
clear
while true; do
    # Get a list of files in the current directory
    IFS=$'\n' GLOBIGNORE='*' command eval 'files=($(ls -1))'

    # Check if any files were found
    if [ ${#files[@]} -eq 0 ]; then
        echo "No files found in the current directory."
        exit 1
    fi

    # Display the list of files with numbers
    echo "Files in the current directory:"
    for i in "${!files[@]}"; do
	origsize=`du -hs "${files[$i]}" | awk '{print $1}'`
        #echo "$i. ${files[$i]} "
        echo "$i. ${files[$i]} $origsize"
    done

    # Prompt the user to choose a file
    read -p "Enter the number of the file to search for duplicates, or (q)uit: " choice

    # Check if the choice is to quit
    if [ "$choice" == "q" ]; then
        exit 0
    fi

    # Check if the choice is valid
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -ge "${#files[@]}" ]; then
        echo "Invalid choice. Please enter a valid number or 'q' to quit."
        continue
    fi

    # Get the selected file name
    file_name="${files[$choice]}"

    # Search for duplicates using Spotlight
    duplicates=$(mdfind "kMDItemDisplayName == '$file_name'")

    # Check if any duplicates were found
    if [ -z "$duplicates" ]; then
        echo "/n No duplicates found for '$file_name'"
        continue
    fi

    echo "Duplicates found for '$file_name':"

    # Display duplicates as a numbered menu list
    IFS=$'\n'
    options=($duplicates)
    for i in "${!options[@]}"; do
	mysize=`du -hs ${options[$i]} | awk '{print $1}'`
        echo "$i. rm \"${options[$i]}\" $mysize"
        #echo "$i. ${options[$i]}"
    done

##    # Prompt the user for an action
##    read -p "Enter the number of the duplicate to (o)pen, (d)elete, De(l)ete original, (F)delete folder, or (q)uit: " choice
##    
##
##    case "$choice" in
##        [oO])
##            # Open the selected duplicate
##            read -p "Enter the number of the duplicate to open: " choice
##            if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -ge "${#options[@]}" ]; then
##                echo "Invalid choice. Please enter a valid number."
##                continue
##            fi
##            open "${options[$choice]}"
##            ;;
##        [dD])
##            # Delete the selected duplicate
##            read -p "Enter the number of the duplicate to delete: " choice
##            if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -ge "${#options[@]}" ]; then
##                echo "Invalid choice. Please enter a valid number."
##                continue
##            fi
##            rm "${options[$choice]}"
##            echo "Deleted: ${options[$choice]}"
##            ;;
##        [lL])
##            # Delete the original file
##            rm -r "$file_name"
##            echo "Deleted: $file_name"
##            ;;
##        [F])
##            # Prompt user to choose which folder to delete
##            echo "Folders containing duplicates:"
##            for i in "${!options[@]}"; do
##                dirname=$(dirname "${options[$i]}")
##                echo "$i. $dirname"
##            done
##            read -p "Enter the number of the folder to delete: " choice
##            if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -ge "${#options[@]}" ]; then
##                echo "Invalid choice. Please enter a valid number."
##                continue
##            fi
##            folder=$(dirname "${options[$choice]}")
##            rm -r "$folder"
##            echo "Deleted folder: $folder"
##            ;;
##        [qQ])
##            exit 0
##            ;;
##       *)
##            echo "Invalid choice. Please enter 'o' to open, 'd' to delete, 'D' to delete original, 'F' to delete folder, or 'q' to quit."
##            ;;
##    esac
done
# The End!
