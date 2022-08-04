#!/bin/bash
  
N="$1" # number of folders to move
FROMF="$2" # second parameter passed to script during call. Example: /content/drive/MyDrive/data
WHEREF="$3" #third parameter passed, folder path where to move files


echo MV N FOLDERS SCRIPT
echo moving  "$1" folders from "$FROMF" to "$WHEREF"
i=0
for FOLDER in $FROMF/*; do

    echo folder in process "$FOLDER"
    echo mv "$FOLDER" "$WHEREF"
    mv "$FOLDER" "$WHEREF"
    i=$(( "$i" + 1 ))
    echo "#""$i"
    if [[ "$i" -ge "$N" ]]
    then
            echo operation completed
            exit
    fi
done
