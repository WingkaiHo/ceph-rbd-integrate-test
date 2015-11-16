#!/bin/bash

QUEUE_DEPTH=2
SIZE=5G
RUNTIME=60
DEVICE=/root/test1
RECORD_SIZE=128K
COUNT_VM=0
NETWORK_ADDR=192.168.20.
START_ADDR=7
RESULT_OUT_DIR=/home/hyj/test/
HOST_LIST=./hostlist
SPEED_RATE_LIMIT=40M
IOPS_RATE_LIMIT=100
MODE=write
LIMIT=false
LIMIT_OPT=

while getopts "q:s:d:r:l:t:m:ih" arg
do
	case $arg in
		q)
			QUEUE_DEPTH=$OPTARG
			;;
		s)
			SIZE=$OPTARG
			;;
		d)
			DEVICE=$OPTARG
			;;
		r)
			RECORD_SIZE=$OPTARG
			;;
		l)
			HOST_LIST=$OPTARG		
			;;
		t)
			RUNTIME=$OPTARG
			;;
		m)
			MODE=$OPTARG		
			;;
		i)
			LIMIT=true
			;;
		?)
		echo "-q Queue depth for fio test 1~128" 
		echo "-s Size of file for fio test (K, M, G)."
		echo "-d The device path for fio test such as /dev/sda1"
		echo "-r The bs(record size) for fio test (K, M, G), default is 128K"
		echo "-l The vm ip list file for batch fio test. default ./hostlist"	
		echo "-t Set runtime of fio instance, default is 60 (60 for 60s)"
		echo "-m Set the mode fio. Such as: write read, randwrite, randread"
		echo "-i Limit mode. Limit max read/write speed for seq read/write, or limit max iops for rand read/write."
		exit 1
		;;
	esac
done

#Read vm ip list form hostlist
COUNT_VM=0
while read -r line
do
	hosts[$COUNT_VM]=$line
	((COUNT_VM++))
done < $HOST_LIST


#Create the output directory
if [ $COUNT_VM == "0" ]; then
    echo "the hostlist is empty."
    exit 0
elif [ $COUNT_VM == "1" ]; then
    RESULT_OUT_DIR=~/ceph-pert-test/${hosts[0]}
else
    RESULT_OUT_DIR=~/ceph-pert-test/VMNUM$COUNT_VM-bs$RECORD_SIZE-qd$QUEUE_DEPTH-$MODE
fi


mkdir -p $RESULT_OUT_DIR

if [ $LIMIT == true ];then
	if [[ $MODE == rand* ]];then
		LIMIT_OPT="-rate_iops=$IOPS_RATE_LIMIT"
	else 
		LIMIT_OPT="-rate=$SPEED_RATE_LIMIT"
	fi
fi

#Create fio instance in remote vm
for ((i=0; i<($COUNT_VM); i++)) do
	ip=${hosts[$i]}
	REMOTE_OUTPUT_FILE="$ip-VMNUM$COUNT_VM-bs$RECORD_SIZE-qd$QUEUE_DEPTH-$MODE"
	remote_cmd="fio -ioengine=libaio -bs=$RECORD_SIZE -direct=1 -thread -rw=$MODE -size=$SIZE -filename=$DEVICE -iodepth=$QUEUE_DEPTH -runtime=$RUNTIME -name=$REMOTE_OUTPUT_FILE $LIMIT_OPT"
	ssh_cmd="ssh -f root@$ip $remote_cmd > $REMOTE_OUTPUT_FILE &"
	ssh_cmd=$ssh_cmd' echo $!'
	#Run and get fio instance pid from remote host
	pid=$($ssh_cmd)
	pids[$i]=$pid
	echo "Create fio instance on host: $ip the pid is $pid"
done

#Wait for all instance which in remote host terminlated, and send the result to local host
for ((i=0; i<($COUNT_VM); i++)) do
	#Get pid of remote host
	pid=${pids[$i]}
	#Get ip of remote host
	ip=${hosts[$i]}

	echo "Waitting for fio instance on host: $ip the pid is $pid...."
	ssh root@$ip "while ps -p $pid >/dev/null; do sleep 1; done"
	REMOTE_OUTPUT_FILE="$ip-VMNUM$COUNT_VM-bs$RECORD_SIZE-qd$QUEUE_DEPTH-$MODE"
	echo "Resend the result $REMOTE_OUTPUT_FILE to local host."
	#Send the result from
	pid=$(scp root@$ip:/root/$REMOTE_OUTPUT_FILE $RESULT_OUT_DIR & echo $!)	
	scp_pids[$i]=$pid
	#((scp root@$ip:/root/$REMOTE_OUTPUT_FILE $RESULT_OUT_DIR) & pids[$i]=$!)
done

#wait for all scp instance finished
for ((i=0; i<($COUNT_VM); i++)) do
	while ps -p ${scp_pids[$i]} >/dev/null; 
	do 
		sleep 1; 
	done
done
sleep 1
