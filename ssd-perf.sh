#!/bin/bash

CURR_PATH=$(cd "$(dirname "$0")"; pwd)
SIZE=5G
RUNTIME=60
DEVICE=/root/test
SSD_HOST_LIST=$CURR_PATH/ssd

while getopts "s:d:t:l:h" arg
do
	case $arg in
		s)
			SIZE=$OPTARG
			;;
		d)
			DEVICE=$OPTARG
			;;
		t)
			RUNTIME=$OPTARG
			;;
		l)
			SSD_HOST_LIST=$OPTARG
			;;
		?)
		echo "-s Size of file for fio test, please set the whole disk size (K, M, G)."
		echo "-d The device path for fio test such as /dev/sda"
		echo "-t Set runtime of fio instance, default is 60 (60 for 60s)"
		echo "-l The ssd host list to submit fio test instance."	
		exit 1
		;;
	esac
done

if [ ! -e $SSD_HOST_LIST ]; then
	echo "Invalid ssh host list path. Please use arg -l to select the ssd host list file path!"
	exit 1
fi

HOSTS_COUNT=0

#read ssd host list
while read -r line
do
	hosts[$HOSTS_COUNT]=$line
	((HOSTS_COUNT++))
done < $SSD_HOST_LIST

if [ $HOSTS_COUNT -eq 0 ]; then
	echo "The list in the file $SSD_HOST_LIST is empty."
	exit 1
fi


MODE_TYPE="write read"
BS_LEVEL="128K 256K 512K 1M"
QUEUE_DEPTH_LEVEL="1 2 4 8 16 32 64 128 512 1024"
USE_CASES=0

#build the seq write/read test case
for mode in $MODE_TYPE
do
	for bs in $BS_LEVEL
	do
		for queue_deph in $QUEUE_DEPTH_LEVEL
		do
			ARG_BS[$USE_CASES]=$bs
			ARG_DEPTH[$USE_CASES]=$queue_deph
			ARG_MODE[$USE_CASES]=$mode
			((USE_CASES++))
		done
	done
done


BS_LEVEL="4K 8K 16K 32K 64K 128K"
MODE_TYPE="randwrite randread"
QUEUE_DEPTH_LEVEL="1 2 4 8 16 32 64 128 512 1024"

#build the rand write/read test case
for mode in $MODE_TYPE
do
	for bs in $BS_LEVEL
	do
		for queue_deph in $QUEUE_DEPTH_LEVEL
		do
			ARG_BS[$USE_CASES]=$bs
			ARG_DEPTH[$USE_CASES]=$queue_deph
			ARG_MODE[$USE_CASES]=$mode
			((USE_CASES++))
		done
	done
done


USED=0
#Create the test case in different host to test ssd write, read, rand read/write perf
for ((i=0; i<$USE_CASES; i++)) do
	if [[ $USED -lt $HOSTS_COUNT ]]; then
		hl=$CURR_PATH/${hosts[$USED]}
		#set tmp task hostlist 
		echo "${hosts[$USED]}" > $hl
		echo "$hl"
		#pids[$USED]=$($CURR_PATH/p-fio.sh -q ${ARG_DEPTH[$i]} -s $SIZE -d $DEVICE -r ${ARG_BS[$i]} -l $hl -m ${ARG_MODE[$i]} -t $RUNTIME & echo $!)
		$CURR_PATH/p-fio.sh -q ${ARG_DEPTH[$i]} -s $SIZE -d $DEVICE -r ${ARG_BS[$i]} -l $hl -m ${ARG_MODE[$i]} -t $RUNTIME &
		pids[$USED]=$!
		((USED++))
	else
		echo "Wait number of task finished in used host...."
		sleep $RUNTIME

		#waiting for pid finished
		for ((j=0; j<$USED; j++)) do
			while ps -p ${pids[$j]} >/dev/null; 
			do 
				sleep 1; 
			done
		done	
		USED=0
		hl=$CURR_PATH/${hosts[$USED]}
		#set tmp task hostlist 
		echo "${hosts[$USED]}" > $hl
		echo "$hl"
		#pids[$USED]=$($CURR_PATH/p-fio.sh -q ${ARG_DEPTH[$i]} -s $SIZE -d $DEVICE -r ${ARG_BS[$i]} -l $hl -m ${ARG_MODE[$i]} -t $RUNTIME & echo $!)
		$CURR_PATH/p-fio.sh -q ${ARG_DEPTH[$i]} -s $SIZE -d $DEVICE -r ${ARG_BS[$i]} -l $hl -m ${ARG_MODE[$i]} -t $RUNTIME &
		pids[$USED]=$!
		((USED++))
	fi
done


#waiting for pid finished
for ((j=0; j<$USED; j++)) do
	while ps -p ${pids[$j]} >/dev/null; 
	do 
		sleep 1; 
	done
done
USED=0

#cp the result to output dir
RSULT_OUT_DIR=~/ceph-pert-test/ssd-perf-`date +%s`
mkdir -p $RSULT_OUT_DIR

#move the result to outputdir
for ((i=0; i<$HOSTS_COUNT; i++)) do
	hl=$CURR_PATH/${hosts[$i]}
	ip=${hosts[$i]}
	#remove the hostlist file
	rm $hl
	#move ssd test result from ip directory to output dir
	cp ~/ceph-pert-test/$ip/* $RSULT_OUT_DIR/
	#remove the tmp result
	rm -rf ~/ceph-pert-test/$ip/
done

echo "The ssd perf test finished, the result output to directory $RSULT_OUT_DIR"
