#!/bin/bash 

CURR_PATH=$(dirname $_)

while getopts "d:h" arg
do
	case $arg in
		d)
			DIR_TO_STAT=$OPTARG
			;;
		?)
		echo "-d The directory to statistics multi vm disk avg perf"
		exit 1
		;;
	esac
done

basename_str=$(basename $DIR_TO_STAT)


vmnum=$(echo $basename_str | awk -F "-" '{print $1}')
vmnum=${vmnum#VMNUM}

bs=$(echo $basename_str | awk -F "-" '{print $2}')
bs=${bs#bs}

iodepth=$(echo $basename_str | awk -F "-" '{print $3}')
iodepth=${iodepth#qd}

mode=$(echo $basename_str | awk -F "-" '{print $4}')

if [ -z "$vmnum" ] || [ -z "$bs" ] || [ -z "$iodepth" ] || [ -z "$mode" ]; then
	echo "Invalid multi vm perf output directory."
	exit 1
fi

if [ ! -d $DIR_TO_STAT ]; then 
	echo "The directory $DIR_TO_STAT do not exist."
	exit 1
fi


files=$(ls $DIR_TO_STAT/*-VMNUM$vmnum-bs$bs-qd$iodepth-$mode 2>/dev/null)

COUNT_FILES=0

iops_sum=0
bw_sum=0
util_sum=0
lat95th_sum=0
avg_lat_sum=0

for file in $files
do
	result_str=$($CURR_PATH/analyze-fio-result.sh -f $file)
	iops_str=$(echo $result_str | awk -F "," '{print $5}' | awk -F "iops=" '{print $2}')
	bw_str=$(echo $result_str | awk -F "," '{print $6}'| awk -F "bw=" '{print $2}' | awk -F "B/s" '{print $1}')

	#convert number to MB/s 
	if [[ $bw_str =~ "K" ]]; then
		bw_str=$(echo $bw_str |awk -F "K" '{print $1}')
		bw_str=$(echo "scale=2;$bw_str/1024" | bc)
	elif [[  $bw_str =~ "M" ]]; then
		bw_str=$(echo $bw_str |awk -F "M" '{print $1}')
	else
		bw_str=$(echo "scale=2;$bw_str/(1024*1024)" | bc)
	fi

	lat_95th_str=$(echo $result_str | awk -F "," '{print $7}' | awk -F "95.00th_lat=" '{print $2}')
	avg_lat_str=$(echo $result_str | awk -F "," '{print $8}' | awk -F "avg=" '{print $2}')
	util_str=$(echo $result_str | awk -F "," '{print $9}' | awk -F "util=" '{print $2}' | awk -F "%" '{print $1}')	

	iops_sum=$iops_sum"+"$iops_str
	bw_sum=$bw_sum"+"$bw_str
	util_sum=$util_sum"+"$util_str
	lat95th_sum=$lat95th_sum"+"$lat_95th_str
	avg_lat_sum=$avg_lat_sum"+"$avg_lat_str
	((COUNT_FILES++))
done

if [ ! $COUNT_FILES -eq $vmnum ]; then 
	echo "VMNUM=$vmnum bs=$bs iodepth=$iodepth mode=$mode: The number of file($COUNT_FILES) not equal the number vm($vmnum)"
	exit 1
fi

avg_iops=$(echo "scale=4;($iops_sum)/$COUNT_FILES" | bc)
avg_bw=$(echo "scale=4;($bw_sum)/$COUNT_FILES" | bc )
avg_disk_lat=$(echo "scale=4;($avg_lat_sum)/$COUNT_FILES" | bc)
avg_lat95th=$(echo "scale=4;($lat95th_sum)/$COUNT_FILES" | bc)
avg_util=$(echo "scale=4;($util_sum)/$COUNT_FILES" | bc)

iops_sum=$(echo "$iops_sum" | bc)
bw_sum=$(echo "$bw_sum" | bc)

echo "VMNUM=$vmnum, bs=$bs, iodepth=$iodepth, mode=$mode, iops=$avg_iops, bw=$avg_bw MB/s, avg_lat=$avg_disk_lat, 95.00th_lat=$avg_lat95th, util=$avg_util% iops_sum=$iops_sum bw_sum=$bw_sum MB/s"
