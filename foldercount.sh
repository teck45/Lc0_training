#!/bin/bash
  
FOLDERPATH="$1"

echo FOLDER COUNTER SCRIPT

i=0
if [ "$(ls -A $FOLDERPATH)" ]
then
for FOLDER in $FOLDERPATH/*; do
    i=$(( "$i" + 1 ))
done
echo "$1" has "$i" folders
else
echo $1 is empty
fi
