#!/bin/bash 

CURR_PATH=$(cd "$(dirname "$0")"; pwd)

while getopts "d:h" arg
do
	case $arg in
		d)
			FIO_RESULT_DIR=$OPTARG
			;;
		?)
		echo "-d assign the disk test result dir."
		exit 1
		;;
	esac
done


BS_LEVEL="128K 256K 512K 1M"
MODE_TYPE="read write"
#dump the seq write and read perf
for mode in $MODE_TYPE
do
	echo "=====================seq$mode perf===================="
	for bs in $BS_LEVEL
	do
		files=$(ls $FIO_RESULT_DIR/*-VMNUM*-bs$bs-*-$mode 2>/dev/null)
		for file in $files 
		do
			result_str=$($CURR_PATH/analyze-fio-result.sh -f $file)
			iodepth=$(echo $result_str | awk -F "," '{print $4}')
			iops=$(echo $result_str | awk -F "," '{print $5}')
			bw=$(echo $result_str | awk -F "," '{print $6}')
			lat_95th=$(echo $result_str | awk -F "," '{print $7}')
			avg_lat=$(echo $result_str | awk -F "," '{print $8}')
			util=$(echo $result_str | awk -F "," '{print $9}')
			echo bs=$bs $iodepth $iops $bw $lat_95th $avg_lat $util
		done	
		echo "======================================================="
	done
	echo ""
done

BS_LEVEL="4K 8K 16K 32K 64K 128K"
MODE_TYPE="randread randwrite"
for mode in $MODE_TYPE
do
	echo "=====================$mode perf===================="
	for bs in $BS_LEVEL
	do
		files=$(ls $FIO_RESULT_DIR/*-VMNUM*-bs$bs-*-$mode 2>/dev/null)
		for file in $files
		do
			result_str=$($CURR_PATH/analyze-fio-result.sh -f $file)
			iodepth=$(echo $result_str | awk -F "," '{print $4}')
			iops=$(echo $result_str | awk -F "," '{print $5}')
			bw=$(echo $result_str | awk -F "," '{print $6}')
			lat_95th=$(echo $result_str | awk -F "," '{print $7}')
			avg_lat=$(echo $result_str | awk -F "," '{print $8}')
			util=$(echo $result_str | awk -F "," '{print $9}')
			echo bs=$bs $iodepth $iops $bw $lat_95th $avg_lat $util
		done
		echo "======================================================="
	done
	echo ""
done
