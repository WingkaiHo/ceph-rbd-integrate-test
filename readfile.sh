#!/bin/bash

CURR_PATH=$(dirname $_)
testfile=$1
COUNT=0

MODE=read

if [[ $MODE == rand* ]];then
	LIMIT_OPT="-rate_iops=$IOPS_RATE_LIMIT"
else 
	LIMIT_OPT="-rate=$SPEED_RATE_LIMIT"
fi  

echo $LIMIT_OPT

if [ ! -e $1 ]; then 
	echo "----------------"
fi

while read -r line
do
	host[$COUNT]=$line
	let COUNT=($COUNT+1)
done < $testfile

for ((i=0; i<$COUNT; i++)) do
	echo ${host[$i]} 
done

echo $COUNT 

if [ $COUNT == "0" ]; then
	echo "exit"
	exit 0
elif [ $COUNT == "1" ]; then
	RESULT_OUT_DIR=~/ceph-pert-test/${host[0]}
else
	RESULT_OUT_DIR=~/ceph-pert-test/VMNUM$COUNT_VM-bs$RECORD_SIZE-qd$QUEUE_DEPTH-$MODE
fi

if [ -e $1 ]; then 
	echo "----------------"
fi

echo $RESULT_OUT_DIR
echo $CURR_PATH
