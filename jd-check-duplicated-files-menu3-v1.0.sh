#!/bin/bash

#Variables
screen_width=2560												# iMac Mini 27"
screen_height=1440												# iMac Mini 27600
cols=2
rows=3
finder_width=1600												# 1/3 of 2560
finder_height=600												# 1/3 of 1440

# Functions
function open_finder {
 if [ "$count1" = "1" ] ;  then
	finder_width=$(( $finder_width * $count1 ));finder_height=$(( $finder_height * $count1 ))
	osascript -e "tell application \"Finder\" to set new_window to make new Finder window to (POSIX file \"$real_path_item\")" \
		-e "tell application \"Finder\" to set the bounds of window 1 to {0, 0, $finder_width, $finder_height}" \
		-e "tell application \"Finder\" to activate"

 elif [ "$count1" = "2" ] ; then
	finder_width=$(( $finder_width * $count1 ));finder_height=$(( $finder_height * $count1 ))
	osascript -e "tell application \"Finder\" to set new_window to make new Finder window to (POSIX file \"$real_path_item\")" \
		-e "tell application \"Finder\" to set the bounds of window 1 to {0, 0, $finder_width, $finder_height}" \
		-e "tell application \"Finder\" to activate"

 elif [ "$count1" = "3" ] ; then
	finder_width=$(( $finder_width * $count1 ));finder_height=$(( $finder_height * $count1 ))
	osascript -e "tell application \"Finder\" to set new_window to make new Finder window to (POSIX file \"$real_path_item\")" \
		-e "tell application \"Finder\" to set the bounds of window 1 to {0, 0, $finder_width, $finder_height}" \
		-e "tell application \"Finder\" to activate"

 elif [ "$count1" = "4" ] ; then
	finder_width=$(( $finder_width * $count1 ));finder_height=$(( $finder_height * $count1 ))
		osascript -e "tell application \"Finder\" to set new_window to make new Finder window to (POSIX file \"$real_path_item\")" \
		-e "tell application \"Finder\" to set the bounds of window 1 to {0, 0, $finder_width, $finder_height}" \
		-e "tell application \"Finder\" to activate"

 elif [ "$count1" = "5" ] ; then
	finder_width=$(( $finder_width * $count1 ));finder_height=$(( $finder_height * $count1 ))
	osascript -e "tell application \"Finder\" to set new_window to make new Finder window to (POSIX file \"$real_path_result\")" \
		-e "tell application \"Finder\" to set the bounds of window 1 to {833, 480, 1666, 960}" \
		-e "tell application \"Finder\" to activate"

 elif [ "$count1" = "6" ] ; then
	finder_width=$(( $finder_width * $count1 ));finder_height=$(( $finder_height * $count1 ))
	osascript -e "tell application \"Finder\" to set new_window to make new Finder window to (POSIX file \"$real_path_result\")" \
		-e "tell application \"Finder\" to set the bounds of window 1 to {1666, 480, 2499, 960}" \
		-e "tell application \"Finder\" to activate"

 elif [ "$count1" = "7" ] ; then
	finder_width=$(( $finder_width * $count1 ));finder_height=$(( $finder_height * $count1 ))
	osascript -e "tell application \"Finder\" to set new_window to make new Finder window to (POSIX file \"$real_path_result\")" \
		-e "tell application \"Finder\" to set the bounds of window 1 to {0, 960, 833, 1440}" \
		-e "tell application \"Finder\" to activate"

 elif [ "$count1" = "8" ] ; then
	finder_width=$(( $finder_width * $count1 ));finder_height=$(( $finder_height * $count1 ))
	osascript -e "tell application \"Finder\" to set new_window to make new Finder window to (POSIX file \"$real_path_result\")" \
		-e "tell application \"Finder\" to set the bounds of window 1 to {833, 960, 1666, 1440}" \
		-e "tell application \"Finder\" to activate"

 elif [ "$count1" = "9" ] ; then
	finder_width=$(( $finder_width * $count1 ));finder_height=$(( $finder_height * $count1 ))
	osascript -e "tell application \"Finder\" to set new_window to make new Finder window to (POSIX file \"$real_path_result\")" \
		-e "tell application \"Finder\" to set the bounds of window 1 to {1666, 960, 2499, 1440}" \
		-e "tell application \"Finder\" to activate"
 fi
}

function decision_time {
	echo -n "Quit (q) | Open all in finder windows (f) | Or press any other key to continue ...? "
	read -n 1 -s -r ans
	if [[ "$ans" =~ [qQ] ]]; then
		exit 0	
 	elif  [[ "$ans" =~ [fF] ]]; then
		echo "do stuff"	
	
 	else
		echo "Move on ....  "
fi
}

clear
# Use a loop to iterate through files in the current directory
clear
echo -e "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo -e "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo -e " This script looks in local folder and finds duplicates using spotlight (mdfind) +++++++++++++++++++++++++++++++++++++++++++++"
echo -e "  it currently works best if you are in a "duplicate" tree / backup ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo -e "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
echo "Items in the current directory:"

IFS=$'\n' # Set Internal Field Separator to newline to handle spaces in folder names

for item in *; do

    # check folders for duplicates first, and provide size info for all duplicates, and give a patch that can be copied for deleting ....
    # 		RFE_01 - provide a list of numbers to select to auto delete...

    if [[ -d "$item" ]]; then											# is "item" a folder ?
        echo -e "\n================ Folder = $item"
	results=$(mdfind "kMDItemFSName == '$item'")								# ask spotlight if there are any mathing folders
	results_length=${#results[@]}										 # store the number of matches from mdfind
    														
    	if [[ -n "$results" ]]; then										# Check if the item (folder) was found in spotlight
		count1=1
		real_path_item=`realpath $item`									# store the name with full path
		local_size=`du -ks "${item}"| awk '{print $1}'`							# get the size of the local folder
		local_file_count=$(find "$item" -type f | wc -l)						# get the number of files under the local folder
		local_file_count_trimmed=${local_file_count#"${local_file_count%%[![:space:]]*}"}		  # massage the number of files

		echo -e "Folder '$item' copy found elsewhere in spotlight ...: "				# output mdfind matches

		#printf "%-20s %-30s %-30s\n" "local folder > " "size:$local_size/count:$local_file_count_trimmed" "rm -r \"$real_path\""
		printf "%-20s %-30s %-30s" "$count1. local folder > " "size:$local_size/count:$local_file_count_trimmed" "" #"rm -r \"$real_path\""
		
	 	printf "remote folders > \n"									# get ready to display duplicates found by mdfind

		for result in $results; do									# loop through items found by mdfind
			real_path_result=`realpath $result`							# get the path of the mdfind matches
			remote_size=`du -ks "${result}"| awk '{print $1}'`
			remote_file_count=$(find "$result" -type f | wc -l)
			remote_file_count_trimmed=${remote_file_count#"${remote_file_count%%[![:space:]]*}"}

			# this loop checks if the result matches the original THEN if not, compares the discovered duplicate
			if [ "$count1" = "1" ]; then open_finder; count1=$(( $count1 + 1 )); fi
			if [ "$real_path" = "$result" ] && [ "$results_length" -eq "1" ]; then                  # make sure mdfind does not return the original item
				printf "%-20s %-30s %-30s\n" "No duplicates found in mdfind...!" "" ""
			elif [ "$local_size" -eq "$remote_size" ] ; then
				comparison="same"
				#printf "%-20s %-30s %-30s\n" "${count1}.   $comparison" "size:${remote_size}/count:$remote_file_count_trimmed" "rm -r \"$result\""
				printf "%-20s %-30s %-30s\n" "${count1}.   $comparison" "size:${remote_size}/count:$remote_file_count_trimmed" "" #"rm -r \"$result\""
				open_finder	
				count1=$(( $count1 + 1 ))
			else
				comparison="diff"
				#printf "%-20s %-30s %-30s\n" "${count1}.   $comparison" "size:${remote_size}/count:$remote_file_count_trimmed" "rm -r \"$result\""
				printf "%-20s %-30s %-30s\n" "${count1}.   $comparison" "size:${remote_size}/count:$remote_file_count_trimmed" "" #"rm -r \"$result\""
				open_finder	
				count1=$(( $count1 + 1 ))
			fi
		done
		

    	else
     	   echo -e "Folder '$item' not found in spotlight."
    	fi
echo ""
decision_time

    fi
    # check files ...
    if [[ -f "$item" ]]; then
        echo -e "\n================ File = $item"
	result=$(mdfind "kMDItemFSName == '$item'")
    	# Check if the item was found in spotlight
    	if [[ -n "$results" ]]; then
		echo -e "Item '$item' found in spotlight ...: "
		echo -e "Remove local? rm \"$item\""
		echo -e "Remove remote?"
		echo -e "\t rm \"$results\""
    	else
     	   echo -e "File '$item' not found in spotlight."
    	fi
      fi
done
# The End!
