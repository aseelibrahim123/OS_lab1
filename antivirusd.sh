#!/bin/bash

scan_dir="$1"
malicious_dir="$2"
interval_secs="$3"


if [ "$#" -ne 3 ]; then
    echo "Missing arguments <scan_dir> <malicious_dir> <interval_secs>"
    exit 1
fi


scan_virus() {

    for file in "$scan_dir"/*
    do
        filename=$(basename "$file")
        has_virus=false

        case "$filename" in
            *.exe|*.bat|*.vbs|*.scr|*.ps1)
                has_virus=true
                ;;
        esac

        if [ "$has_virus" = false ]; then
            if grep -Eiq 'virus|trojan|malware|worm|ransomware' "$file"; then
                has_virus=true
            fi
        fi

        if [ "$has_virus" = true ]; then
            mv "$file" "$malicious_dir/"
            echo "$file is malicious and it is DELETED"
        fi
    done
}


while true
do

    if [ -f "directory-info.last" ]; then

        ls -l "$scan_dir" > directory-info.new

        if ! diff -q directory-info.new directory-info.last > /dev/null; then

            scan_virus
            
            cp directory-info.new directory-info.last
        fi

    else

        scan_virus
        
        ls -l "$scan_dir" > directory-info.last
    fi

    sleep "$interval_secs"

done
