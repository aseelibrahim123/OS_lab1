#!/bin/bash

scan_dir="$1"
malicious_dir="$2"
WHITELIST_FILE="whitelist.txt"

if [ "$#" -ne 2 ]; then
    echo "Missing arguments <scan_dir> <malicious_dir>"
    exit 1
fi

while true
do
    if [ -z "$(ls -A "$malicious_dir")" ]; then
        echo "No malicious files to review."
        break
    else

        echo "Malicious files:"
        
        files=("$malicious_dir"/*)
        
        for i in "${!files[@]}"
        do
            echo "$((i + 1)). $(basename "${files[$i]}")"
        done

        echo -n "Enter the number of the file you want to review: "
        read file_number

        if ! [[ "$file_number" =~ ^[0-9]+$ ]] || [ "$file_number" -lt 1 ] || [ "$file_number" -gt "${#files[@]}" ]; then
            echo "Invalid file number. Please try again."
            continue
        fi

        selected_file="${files[$((file_number - 1))]}"
        filename=$(basename "$selected_file")

        echo
        echo "What do you want to do with $filename?"
        echo "1. Restore file"
        echo "2. Permanently delete file"
        echo "3. Go back to file list"
        echo -n "Enter your choice: "
        read choice

        if [ "$choice" -eq 1 ]; then
            mv "$selected_file" "$scan_dir"
            
            touch "$WHITELIST_FILE"
            realpath "$scan_dir/$filename" >> "$WHITELIST_FILE"
    
            echo "Restored $filename to $scan_dir"

        elif [ "$choice" -eq 2 ]; then
            rm "$selected_file"
            echo "$filename permanently deleted."

        elif [ "$choice" -eq 3 ]; then
            continue

        else
            echo "Invalid input."
        fi
    fi
done
