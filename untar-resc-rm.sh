#!/bin/bash
# This script will untar, rescore and remove .tar and unpacked folders, file by file saving SSD space as it usually needed, leaving only rescored data
INPUTF="/mnt/t80raw2nd" #"$1"  #in case of using admin ~ use whole path /home/admin/, utility to look on full path realpath
UNTARF="/home/admin/untarf" #"$2"
ROUTPUTF="/mnt/t80second-train-r" #"$3"
RESCORERPATH="/mnt/lc0-rescore_tb/build/release" #$3  #path to folder where rescorer is
SYZYGYPATH="/mnt/syzygy" # $4

echo untar rescore and remove script started
cd "$INPUTF"
for FILE in "$INPUTF"/*; do
        cd "$INPUTF"
        echo "$FILE"
        echo tar -xf "$FILE" -C "$UNTARF"
        tar -xf "$FILE" -C "$UNTARF"
        echo RFOLDERPATH="$UNTARF""/""$( basename "$FILE" .tar )"
        RFOLDERPATH="$UNTARF""/""$( basename "$FILE" .tar )"
        echo cd "$ROUTPUTF"
        cd "$ROUTPUTF"
        echo mkdir $( basename "$FILE" .tar )
        mkdir $( basename "$FILE" .tar )
        echo cd "$RESCORERPATH" && ./rescorer rescore --delete-files=false --syzygy-paths="$SYZYGYPATH" --threads=20 --input="$RFOLDERPATH" --output="$ROUTPUTF""/""$(basename "$FILE" .tar)" --deblunder=true --deblunder-q-blunder-threshold=0.10 --deblunder-q-blunder-width=0.06
        cd "$RESCORERPATH" && ./rescorer rescore --delete-files=false --syzygy-paths="$SYZYGYPATH" --threads=20 --input="$RFOLDERPATH" --output="$ROUTPUTF""/""$(basename "$FILE" .tar)" --deblunder=true --deblunder-q-blunder-threshold=0.10 --deblunder-q-blunder-width=0.06
        echo rm "$FILE"
        echo rm -rf "$RFOLDERPATH"
        rm "$FILE"
        rm -rf "$RFOLDERPATH"
done
