#!/bin/bash

CURR_PATH=$(cd "$(dirname "$0")"; pwd)
SIZE=5G
RUNTIME=60
DEVICE=/root/test

while getopts "s:d:t:h" arg
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
		?)
		echo "-s Size of file for fio test, please set the whole disk size (K, M, G)."
		echo "-d The device path for fio test such as /dev/sda"
		echo "-t Set runtime of fio instance, default is 60 (60 for 60s)"
		exit 1
		;;
	esac
done

BS_LEVEL="128K 256K 512K 1M"
QUEUE_DEPTH_LEVEL="1 2 4 8 16"

HOST_LIST=$CURR_PATH/sata
for bs in $BS_LEVEL
do
	for queue_deph in $QUEUE_DEPTH_LEVEL
	do
		#The sata sequence write perf
		$CURR_PATH/p-fio.sh -q $queue_deph -s $SIZE -d $DEVICE -r $bs -l $HOST_LIST -m write -t $RUNTIME
		#The sata sequence read perf
		$CURR_PATH/p-fio.sh -q $queue_deph -s $SIZE -d $DEVICE -r $bs -l $HOST_LIST -m read -t $RUNTIME
	done
done

BS_LEVEL="4K 8K 16K 32K 64K 128K"
QUEUE_DEPTH_LEVEL="1 2 4 8 16 32"
for bs in $BS_LEVEL
do
	for queue_deph in $QUEUE_DEPTH_LEVEL
	do
		#The sata rand write iops perf
		$CURR_PATH/p-fio.sh -q $queue_deph -s $SIZE -d $DEVICE -r $bs -l $HOST_LIST -m randwrite -t $RUNTIME	
		#The sata rand read perf
		$CURR_PATH/p-fio.sh -q $queue_deph -s $SIZE -d $DEVICE -r $bs -l $HOST_LIST -m randread -t $RUNTIME
	done
done

while read -r line
do
	ip=$line
done < $HOST_LIST

RSULT_OUT_DIR=~/ceph-pert-test/sata-perf-`date +%s`

mv ~/ceph-pert-test/$ip $RSULT_OUT_DIR
echo "The sata perf test finished, the result output to directory $RSULT_OUT_DIR"
