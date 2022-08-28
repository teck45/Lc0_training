#!/bin/bash
# This script will untar and remove .tar and unpacked folders, file by file saving SSD space as it usually needed, leaving only rescored data

#MAININPUTF="/mnt/t80raw2nd" #"$1"  #in case of using admin ~ use whole path /home/admin/, utility to look on full path realpath
#MAINUNTARF="/home/admin/untarf" #"$2"
#REMOVE=$3
MAININPUTF="$1"  #in case of using admin ~ use whole path /home/admin/, utility to look on full path realpath
MAINUNTARF="$2"

echo untar rescore and remove script started


for INPUTF in "$MAININPUTF"/*; do
        echo cd $MAINUNTARF && mkdir $( basename "$INPUTF" )
        cd $MAINUNTARF && mkdir $( basename "$INPUTF" )

        UNTARF="$MAINUNTARF""/"$( basename "$INPUTF" )
        echo TAR OUTPUT FOLDER "$UNTARF"
        cd "$INPUTF"
for FILE in "$INPUTF"/*; do
        cd "$INPUTF"
        echo "$FILE"
        echo tar -xf "$FILE" -C "$UNTARF"
        tar -xf "$FILE" -C "$UNTARF"

        echo rm "$FILE"
        rm "$FILE"
done
done
