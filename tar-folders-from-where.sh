#!/bin/bash
  
FROMF="$1" # path from where to tar folders, example: /content/drive/MyDrive/data
WHEREF="$2" # path where to save tar files

echo TAR FOLDERS SCRIPT
echo Packing folders from "$FROMF" to "$WHEREF"
i=0
cd "$FROMF"
for FOLDER in $FROMF/*; do

    echo folder in process "$FOLDER"
    i=$(( $i + 1 ))

    echo tar -cf "$WHEREF""/""$(basename "$FOLDER")".tar "$(basename "$FOLDER")"  
    tar -cf "$WHEREF""/""$(basename "$FOLDER")".tar "$(basename "$FOLDER")" 
    echo "#""$i"

done
