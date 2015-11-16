#!/bin/bash 

CURR_PATH=$(cd "$(dirname "$0")"; pwd)

while getopts "d:h" arg
do
	case $arg in
		d)
			DIR_TO_STAT=$OPTARG
			;;
		?)
		echo "-d The directory to statistics multi vm test case."
		exit 1
		;;
	esac
done


if [ ! -d $DIR_TO_STAT ]; then 
	echo "The directory $DIR_TO_STAT do not exist."
	exit 1
fi



MODE_TYPE="read write randread randwrite"

for mode in $MODE_TYPE
do
	echo "//-------------------------------------------------------"
	echo "//                  $mode"
	echo "//-------------------------------------------------------"

	if [ $mode == "read" ] || [ $mode == "write" ]; then
		BS_LEVEL="128K 256K 512K 1M"
	else
		BS_LEVEL="4K 8K 16K 32K 64K 128K"
	fi

	for bs in $BS_LEVEL 
	do
		dirs=$(ls -d $DIR_TO_STAT/VMNUM*-bs$bs-qd*-$mode 2>/dev/null )
		for dir in $dirs 
		do
			if [ -d $dir ]; then
				$CURR_PATH/stat-multi-perf.sh -d $dir
			fi
		done
	done
done

