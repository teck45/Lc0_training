#!/bin/bash
  
RFOLDERPATH="$1" #"/mnt/rawdatatest/lc0" 
ROUTPUTF="$2" #"/mnt/rescoutput"
RESCORERPATH="/mnt/lc0-rescore_tb/build/release" #$3  #path to folder where rescorer is
SYZYGYPATH="/mnt/syzygy" # $4

echo rescorer started

for RFOLDER in "$RFOLDERPATH"/*; do
        cd "$ROUTPUTF" #current directory to rescorer otput folder so mk dir will be able to create folders
        echo rescoring folder "$RFOLDER"
        echo mkdir $(basename "$RFOLDER")
        mkdir $(basename "$RFOLDER") # creating folder with same name in output folder

        cd "$RESCORERPATH" && ./rescorer rescore --delete-files=false --syzygy-paths="$SYZYGYPATH" --threads=20 --input="$RFOLDER" --output="$ROUTPUTF""/""$(basename "$RFOLDER")" --deblunder=true --deblunder-q-blunder-threshold=0.10 --deblunder-q-blunder-width=0.06

done
