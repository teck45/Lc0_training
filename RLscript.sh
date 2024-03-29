#!/bin/bash

TFFOLDER="/mnt/lczero-training-Nadam-rl/tf"
YAMLPATH="/mnt/config/bt1024-rl-lowlr.yaml"    #"/mnt/config/40b-sicilian-low-lr.yaml"
RESCORERPATH="/mnt/lc0-rescore_tb/build/release"  #path to folder where rescorer executable file is, no / at the end
SYZYGYPATH="/mnt/syzygy"
# so we include this lc0 folder here too :)
STEPSDONEPATH="/mnt/trainstepslog.txt"
STEPSDONE=$(<"$STEPSDONEPATH") # reading stepsdone from logfile
STOPFILEPATH="/mnt/stopfile.txt"
LASTNOSWANETSTAT="$TFFOLDER""/""no_swa_last_net_stat.txt"
LASTSWANETSTAT="$TFFOLDER""/""swa_last_net_stat.txt"

RAWDATAPATH="/mnt/atnb-raw/lc0" # ATTENTION! XDG HOMEPATH creates lc0 folder inside homepath folder
SPECIALRAWDATAPATH="/mnt/special-atnb-raw/lc0"
RAWTESTPATH="/mnt/atnb-raw-test"
SPECIALRAWTESTPATH="/mnt/apecial-atnb-raw-test"

NOTRESCOREDTRAINPATH="/mnt/no-r-train" #Folder where not rescored data is stored, separate from rawdata where clients send their data, and separate from folders used by traininig script
NOTRESCOREDTESTPATH="/mnt/no-r-test"
TRAINDATAPATH="/mnt/train-bt-r"
TESTDATAPATH="/mnt/test-bt-r"
USEDTRAINDATAPATH="/mnt/used-train-bt-r"
USEDTESTDATAPATH="/mnt/used-test-bt-r"

TRAININGSTEP=500 # number of steps equals totalsteps in yaml (one iteration here)
DATAGENLIMITMB=192 #192 mb for 500 steps # 768 #2400 - 100k chunks, 768 for 32k chunks
SPECIALLIMITMB=5
#RLSTARTPATH="./rlstart.sh"
NETSPATH="/mnt2/nets/BT1024-rl-lowlr/"
BASENAMECORE="BT1024-rl-lowlr-" #swa-"
#pick_best_net #launching function to check which net is better (swa vs no swa), result is global BASENAME variable
#BASENAME="$BASENAMECORE""$BESTNET""$STEPSDONE" #BESTNET can be empty "" if no swa is better or "swa-" if swa net is better
#commented because basename calculation moved into pick best net function
#fullnetpath we want as result "/mnt/nets/40b-sicilian-low-lr/40b-sicilian-low-lr-swa-3500.pb.gz", 3500 will be read from trainstepslog.txt (stepsdone), .pb.gz will be added by script

function get_folder_size () {
        FOLDERSIZE=$( du -sm "$RAWDATAPATH" | cut -f1 )
}

function report_folder_size () {
        echo folder size is "$FOLDERSIZE" mb out of "$DATAGENLIMITMB" mb
}

function datageneration () {
	STEPSDONE=$(<"$STEPSDONEPATH") # reading stepsdone from logfile
        pick_best_net #launching function to check which net is better (swa vs no swa), result is global BASENAME variable
#	BASENAME="$BASENAMECORE""$BESTNET""$STEPSDONE" #BESTNET can be empty "" if no swa is better or "swa-" if swa net is better #moved into pick best net function
	echo BEST P ACC NET IS $BESTNET
	FULLNETPATH="$NETSPATH""$BASENAME"".pb.gz"
	echo complete net path for data generation "$FULLNETPATH"
#	cd ~ && "$RLSTARTPATH" "$FULLNETPATH"
        screen -ls
        screen -S rl0 -X quit
        screen -S rl1 -X quit
        screen -S rl2 -X quit
        screen -S rl3 -X quit
        screen -ls

#	screen -dmS rl0 bash -c "~/scripts/dag-ab-datagen0.sh '/mnt/syzygy' '$FULLNETPATH'"
        screen -dmS rl1 bash -c "~/scripts/dag-ab-datagen1.sh '/mnt/syzygy' '$FULLNETPATH'"
#        screen -dmS rl2 bash -c "~/scripts/atnb-datagen2.sh '/mnt/syzygy' '$FULLNETPATH'"
#        screen -dmS rl3 bash -c "~/scripts/atnb-datagen3.sh '/mnt/syzygy' '$FULLNETPATH'"

        echo "   __        /\_/\                         "
        echo "  / /  _____= o_o =                        "
        echo " ( (_./  )_    ^__                         "
        echo "  \__(____)__<___>(@) RL CLIENTS 0,1,2,3 STARTED   "

        echo screen -ls
        screen -ls

}

function rlend ()  {
	echo screen -ls
	screen -ls
	screen -S rl0 -X quit
	screen -S rl1 -X quit
	screen -S rl2 -X quit
	screen -S rl3 -X quit
	screen -S rl0f960 -X quit
	echo closing clients
}

function special_rl_end () {
        echo screen -ls
        screen -ls
	echo closing special client data generation
        screen -S rl0f960 -X quit
        
}

function special_rl_start () {
        echo screen -ls
	screen -dmS rl0f960 bash -c "~/scripts/dag-ab-f960-datagen0.sh '/mnt/syzygy' '$FULLNETPATH'"
        echo special client rl0f960 is started on gpu0
        screen -ls
}

function datagen_one_gpu_start () {
	STEPSDONE=$(<"$STEPSDONEPATH") # reading stepsdone from logfile
        pick_best_net #launching function to check which net is better (swa vs no swa), result is global BASENAME variable
        FULLNETPATH="$NETSPATH""$BASENAME"".pb.gz"
        screen -dmS rl0 bash -c "~/scripts/dag-ab-datagen0.sh '/mnt/syzygy' '$FULLNETPATH'"
        echo standard data generation client is launched using gpu0
        screen -ls
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
	local TESTRATIO=10 #every 10th file will move to outputF, randomly. For 0,9 train ratio parameter equals 10, 20 for 0,95 train ratio etc/
	#TESTRATIO="$3" # will be 3rd parameter during .sh launch from shell when uncommented
		function makedirectory () {
		cd $OUTPUTF && mkdir "$1" # creating directory with $1 FOLDER name
		}
	echo TRAIN TEST DATA SPLITTING SCRIPT
	echo Randomly moving "$TESTRATIO" percent of chunks from "$INPUTF"
	echo to "$OUTPUTF"
	for FOLDER in "$INPUTF"/*; do
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
	local names=( a b c d e f g h i j k l m o p q r s t u v w x y z ab ac ad ae af ag ah ) #each will be added in addition to basename
	local n=0

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

function getnetnumber()  #helper function for mv-first-folder(), will output 123 from name-swa-123a and name-123a
{
local netname=$( basename "$1" )
local i=0
for (( i=${#netname}; i>0; i-- )); do
#  echo "${netname:$i:1}"
  if [[ "${netname:$i:1}" == "-" ]]
  then
    iplus=$(( $i + 1 ))
    netnumber=${netname:$(( $i + 1 )):${#netname}}
    netnumber=$(tr -d 'a-z' <<< "$netnumber") #removing a-z chars from the end of net number 1000a => 1000
    break
  fi
done
}

function analyze_net_stat() {
#$1 string $2 pattern, "returns" net_stat_result as gloval variable 
local line=$1
local pattern=$2 
local length=${#pattern}
echo line pattern len $line $pattern $length
for (( i=0; i<=${#line}; i++ )); do
  local check=${line:i:$length}
  if [[ $check == "$pattern" ]]; # "P Acc=" "V Acc="
  then
    res_i="$i"
    break
  fi
done
  res_i=$(( "$res_i" + "$length" ))
  net_stat_result=${line:$res_i:5}
}

function pick_best_net {
local no_swa_str=$(<"$LASTNOSWANETSTAT")
local swa_str=$(<"$LASTSWANETSTAT")
analyze_net_stat "$no_swa_str" "P Acc="
local NO_SWA_PACC=$net_stat_result
analyze_net_stat "$swa_str" "P Acc="
local SWA_PACC="$net_stat_result"
echo swa p accuracy: "$SWA_PACC""," no swa p accuracy: "$NO_SWA_PACC"
if (( $(echo ""$SWA_PACC" >= "$NO_SWA_PACC"" |bc -l) )); # no floating point operations in bash so bc utility is needed
then
  BESTNET="swa-"
else
  BESTNET=""
fi
BASENAME="$BASENAMECORE""$BESTNET""$STEPSDONE" #BESTNET can be empty "" if no swa is better or "swa-" if swa net is better
}

function mv_first_folder()
{
#local N="$1" # number of network which folders need to be moved out
local FROMF="$1" # second parameter passed to script during call. Example: /content/drive/MyDrive/data
local WHEREF="$2" #third parameter passed, folder path where to move files

echo mv earliest  data folders out
echo cd "$FROMF"
cd "$FROMF"

local MINNUMBER=100000000 # 100M steps is reasonably high number not supposed to exist

for FOLDER in $FROMF/*; do
    getnetnumber "$FOLDER" # function will save output in global variable netnumber
    if [[ "$netnumber" -le "$MINNUMBER" ]]
    then
      MINNUMBER="$netnumber"
    fi
done

echo cd "$FROMF"
cd "$FROMF"
echo mv  *"-""$MINNUMBER"[a-z]* "$WHEREF"
mv  *"-""$MINNUMBER"[a-z]* "$WHEREF" #pattern will use folders with names such as *-123a *-123ab but will not use -1230a
echo operation completed
}

while true
do
        get_folder_size #calling function to calculate folder size
	SPECIALFOLDERSIZE=$( du -sm "$SPECIALRAWDATAPATH" | cut -f1 )

	if [[ "$FOLDERSIZE" -lt "$DATAGENLIMITMB"  ]] 
	then
		rlend #calling function to close clients that may be running
		special_rl_end
                report_folder_size #call function to print folder size
		datageneration  #pathtonetwork
		echo cp f size $SPECIALFOLDERSIZE 
		echo sp limit $SPECIALLIMITMB
		if [[ "$SPECIALFOLDERSIZE" -lt "$SPECIALLIMITMB" ]]
		then
		echo inside loop
		special_rl_start
		fi
        
	special_gen_finished=0

	while [ "$FOLDERSIZE" -lt "$DATAGENLIMITMB" ] # run while we have less data than needed
	do
        	get_folder_size
       		report_folder_size

	        SPECIALFOLDERSIZE=$( du -sm "$SPECIALRAWDATAPATH" | cut -f1 )
                echo special folder size is "$SPECIALFOLDERSIZE" mb out of "$SPECIALLIMITMB" mb
		if [[ "$special_gen_finished" -eq 0 ]] &&  [[ "$SPECIALFOLDERSIZE" -ge "$SPECIALLIMITMB" ]]
		then
		    special_rl_end #closing f960 data generation
		    datagen_one_gpu_start #starting ordinary data gen on gpu 0 instead of special (f960)
		    special_gen_finished=1
		fi
		sleep 10m
	done
	fi
	if [[ "$FOLDERSIZE" -ge "$DATAGENLIMITMB"  ]] # if we have more data than needed call end clients, splitrename and train.py
	then
		echo -n "limit is reached "; report_folder_size # -n will print without new line
		pick_best_net # calling function to check which net is better (swa vs no swa), result is global BESTNET and BASENAME variables
		rlend # calling function to close clients
		special_rl_end #close F960 data generation
		rename "$BASENAME" "$RAWDATAPATH" # folders with rawdata generated by clients will obtain meaningful names (basename+a,b,c..) 
		rename ""F960-""$BASENAME"" "$SPECIALRAWDATAPATH" # renaming f960 folder
		split "$RAWDATAPATH" "$RAWTESTPATH" # first parameter folder with folders to split, second parameter output (test) folder path
		split "$SPECIALRAWDATAPATH" "$SPECIALRAWTESTPATH" #split f960 data
		rescorerf "$RAWDATAPATH" "$TRAINDATAPATH" # syzygy path is variable at the top of script
	       	rescorerf "$RAWTESTPATH" "$TESTDATAPATH"
                rescorerf "$SPECIALRAWDATAPATH" "$TRAINDATAPATH"
		rescorerf "$SPECIALRAWTESTPATH" "$TESTDATAPATH"
		move "$RAWDATAPATH" "$NOTRESCOREDTRAINPATH"
		move "$RAWTESTPATH" "$NOTRESCOREDTESTPATH"
                move "$SPECIALRAWDATAPATH" "$NOTRESCOREDTRAINPATH"
		move "$SPECIALRAWTESTPATH" "$NOTRESCOREDTESTPATH"
		mv_first_folder "$TRAINDATAPATH" "$USEDTRAINDATAPATH"  # FROM WHERE
		mv_first_folder "$TESTDATAPATH" "$USEDTESTDATAPATH"  # FROM WHERE
		train "$YAMLPATH" #calling function to train the net, yaml should be with reasonable totalsteps - rl style
	fi
done
