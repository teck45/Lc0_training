#!/bin/bash

TFFOLDER="/mnt/lczero-training/tf"
YAMLPATH="/mnt/config/40b-sicilian-r.yaml"    #"/mnt/config/40b-sicilian-low-lr.yaml"
RESCORERPATH="/mnt/lc0-rescore_tb/build/release"  #path to folder where rescorer executable file is, no / at the end
SYZYGYPATH="/mnt/syzygy"
RAWDATAPATH="/mnt/rawdata/lc0" # ATTENTION! XDG HOMEPATH creates lc0 folder inside homepath folder
# so we include this lc0 folder here too :)
RAWTESTPATH="/mnt/rawtest"
NOTRESCOREDTRAINPATH="/mnt/notrescoredtrain" #Folder where not rescored data is stored, separate from rawdata where clients send their data, and separate from folders used by traininig script
NOTRESCOREDTESTPATH="/mnt/notrescoredtest"
STEPSDONEPATH="/mnt/trainstepslog.txt"
STOPFILEPATH="/mnt/stopfile.txt"
STEPSDONE=$(<"$STEPSDONEPATH") # reading stepsdone from logfile
RLSTARTPATH="./rlstart.sh"
TRAININGSTEP=500 # number of steps equals totalsteps in yaml (one iteration here)
TRAINDATAPATH="/mnt/train"
TESTDATAPATH="/mnt/test"
DATAGENLIMITMB=1000

BASENAMECORE="40b-sicilian-r-swa-"
BASENAME="$BASENAMECORE""$STEPSDONE"
NETSPATH="/mnt/nets/40b-sicilian-r/"
#fullnetpath we want as result "/mnt/nets/40b-sicilian-low-lr/40b-sicilian-low-lr-swa-3500.pb.gz", 3500 will be read from trainstepslog.txt (stepsdone), .pb.gz will be added by script

FOLDERSIZE=$( du -sm "$RAWDATAPATH" | cut -f1 )

function datageneration () {
	STEPSDONE=$(<"$STEPSDONEPATH") # reading stepsdone from logfile
	BASENAME="$BASENAMECORE""$STEPSDONE"
	FULLNETPATH="$NETSPATH""$BASENAME"".pb.gz"
	echo complete net path for rl "$FULLNETPATH"
	cd ~ && "$RLSTARTPATH" "$FULLNETPATH"

}

function rlend ()  {
	echo screen -ls
	screen -ls
	screen -S rl0 -X quit
	screen -S rl1 -X quit
	screen -S rl2 -X quit
	screen -S rl3 -X quit
	echo closing clients
	echo screen -ls
	screen -ls
	echo sleep 5 seconds to avoid overlay
	sleep 5
}

function split () {
	# This function with 3 parameters will move 10 percent of chunks from untarred train data chunks folders
	# Third parameter (10 percent split) is set in this script but can be changed to $3 parameter too
	# to the test chunks folders with the same name. Script prepares approximately 1 gb of data per minute on hdd and old cpu.
	# command example to make .sh file executable: cd /content/drive/MyDrive/1pipelinescript/ && chmod +x slsplit.sh

	#INPUTF="/content/drive/MyDrive/1pipelinescript/LCDATA"
	#OUTPUTF="/content/drive/MyDrive/1pipelinescript/TESTLCDATA"
	INPUTF="$1" #first parameter passed to script during call. Example: cd /content/drive/MyDrive/1pipelinescript/ && ./slsplit.sh /content/STORAGE /content/TESTSTORAGE
	OUTPUTF="$2" #second parameter passed to script during call. Result after parsing $1 $2 parameters: randomply moving 10 percent of chunks from /content/STORAGE to /content/TESTSTORAGE
	TESTRATIO=10 #every 10th file will move to outputF, randomly. For 0,9 train ratio parameter equals 10, 20 for 0,95 train ratio etc/
	#TESTRATIO="$3" # will be 3rd parameter during .sh launch from shell when uncommented
		function makedirectory () {
		cd $OUTPUTF && mkdir $1 # creating directory with $1 FOLDER name
		}
	echo TRAIN TEST DATA SPLITTING SCRIPT
	echo Randomly moving $TESTRATIO percent of chunks from $INPUTF 
	echo to $OUTPUTF
	for FOLDER in $INPUTF/*; do
	    makedirectory $(basename "$FOLDER")  # $(basename $(dirname "/path/...") )
	    echo folder_in_process $FOLDER
	    for FILE in "$FOLDER"/*;
	    do
	        if [[ $((1 + "$RANDOM" % "$TESTRATIO")) -eq "$TESTRATIO" ]]
	        then
	        mv "$FILE" "$OUTPUTF""/"$( basename "$FOLDER")
	        fi
	    done
	done
}

function rename () {
	# This fucntion will rename folders inside folder to meaninful names (path $2 - second parameter passed)
        # $1 name base $2 path to folder where folders need to be renamed are
	names=( a b c d e f g h i j k l m o p q r s t u v w x y z ab ac ad ae af ag ah ) #each will be added in addition to basename
	n=0

	cd $2  #keep current directory the same as raw data folder to avoid moving files during renaming
	for FLDR in "$2"/*;
	do
	        echo renaming "$FLDR" on "$1""${names["$n"]}"
	        mv "$FLDR" "$1""${names["$n"]}" #adding a b c d e to each folder name
	        echo $n
	        n=$(( $n + 1 ))
	done
}

function move() {
	#this function  will move folders from first folder to second ($1 $2)
	cd $1  #keep folder we are moving from  as current directory to avoid bugs
	for FOLDR in "$1"/*;
	do
	        echo moving "$FOLDR" to $2
	        mv "$FOLDR" $2 #3rd parameter passed to whole script is training directory
	done
}

function rescorerf () {
	#--delete-files=false option is used by rescorer, so input folder files will not be deleted
	#$1 path to folder where files need to be rescored are $2 Folder where folders with rescored data need to be
	#$SYZYGYPATH and $RESCORERPATH variable are on top of the script
	RFOLDERPATH="$1"
	ROUTPUTF="$2"
	
	echo rescorer started

	for RFOLDER in "$RFOLDERPATH"/*; do
        cd "$ROUTPUTF" #current directory to rescorer otput folder so mk dir will be able to create folders
        echo rescoring folder "$RFOLDER" to "$ROUTPUTF"
        echo mkdir $(basename "$RFOLDER")
        mkdir $(basename "$RFOLDER") # creating folder with same name in output folder
        cd "$RESCORERPATH" && ./rescorer rescore --delete-files=false --syzygy-paths="$SYZYGYPATH" --threads=8 --input="$RFOLDER" --output="$ROUTPUTF""/""$(basename "$RFOLDER")" --deblunder=true --deblunder-q-blunder-threshold=0.10 --deblunder-q-blunder-width=0.06
	done
}
function train () {
	#Parameter $1 received is full path to yaml
	cd $TFFOLDER && ./train.py --cfg=$1
	STEPSDONE=$(( "$STEPSDONE" + "$TRAININGSTEP" ))
	echo $STEPSDONE >"$STEPSDONEPATH" #writing stepsdone into trainstepslog file
	STOPSWITCH=$(<"$STOPFILEPATH")
	echo stopswitch is  "$STOPSWITCH"
	if [[ "$STOPSWITCH" == "stop" ]]
	then
		echo training script stopped
		exit
	fi
}

while true
do
	FOLDERSIZE=$( du -sm "$RAWDATAPATH" | cut -f1 )
	if [[ "$FOLDERSIZE" -lt "$DATAGENLIMITMB"  ]] 
	then
		rlend #calling function to close clients that may be running
		datageneration  #pathtonetwork
	while [ "$FOLDERSIZE" -lt "$DATAGENLIMITMB" ] # run while we have less data then needed
	do
        	sleep 30m
        	FOLDERSIZE=$( du -sm "$RAWDATAPATH" | cut -f1 )
       		echo foldersize is "$FOLDERSIZE" mb
	done
	fi
	if [[ "$FOLDERSIZE" -ge "$DATAGENLIMITMB"  ]] # if we have more data then needed call end clients, splitrename and train.py
	then
		echo limit is reached, foldersize is "$FOLDERSIZE" mb
		rlend #calling function to close clients
		rename "$BASENAME" "$RAWDATAPATH" #folders with rawdata generated by clients will obtarin meaninful names (basename+a,b,c..) 
		split "$RAWDATAPATH" "$RAWTESTPATH" # first parameter folder with folders to split, second parameter output (test) folder path
		rescorerf "$RAWDATAPATH" "$TRAINDATAPATH"
	       	rescorerf "$RAWTESTPATH" "$TESTDATAPATH"
		move "$RAWDATAPATH" "$NOTRESCOREDTRAINPATH"
		move "$RAWTESTPATH" "$NOTRESCOREDTESTPATH"
		train $YAMLPATH #calling function to train the net, yaml should be with reasonable totalsteps - rl style
	fi
done
