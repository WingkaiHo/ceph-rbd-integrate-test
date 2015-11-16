#!/bin/bash 

CURR_PATH=$(cd "$(dirname "$0")"; pwd)

while getopts "f:h" arg
do
	case $arg in
		f)
			FIO_RESULT_FILE=$OPTARG
			;;
		?)
		echo "-f assign the fio result file to analize."
		exit 1
		;;
	esac
done


if [ ! -e $FIO_RESULT_FILE ]; then
	echo "ip=0.0.0.0, bs=0, ioqueue=0, mode=read, iops=0, bw=0KB/s, 95.00th=0, avg=0, util=0%"
	exit 1
fi

basename_str=$(basename $FIO_RESULT_FILE)
ip=$(echo $basename_str | awk -F "-" '{print $1}')
ip="ip="$ip

vmnum=$(echo $basename_str | awk -F "-" '{print $2}')
vmnum="VMNUM="${vmnum#VMNUM}

bs=$(echo $basename_str | awk -F "-" '{print $3}')
bs="bs="${bs#bs}

iodepth=$(echo $basename_str | awk -F "-" '{print $4}')
iodepth="iodepth="${iodepth#qd}

mode=$(echo $basename_str | awk -F "-" '{print $5}')
mode="mode="$mode

#get the iops and bw
result_str=$(grep "iops" $FIO_RESULT_FILE)

iops_str=$(echo $result_str | awk -F "," '{print $3}')
bw_str=$(echo $result_str | awk -F "," '{print $2}')

#get 95% latency
result_str=$(grep "95.00th=" $FIO_RESULT_FILE)
tmp=$(echo $result_str | awk -F "," '{print $4}')
lat95th=$(echo $tmp | awk -F "[" '{print $2}' |  awk -F "]" '{print $1}')
result_str=$(grep "clat percentiles (msec)" $FIO_RESULT_FILE)
if [ -z "$result_str" ]; then
	lat95th="95.00th_lat="$lat95th
else
	#change the msec to usec
	lat95th=$(echo $lat95th*1000|bc -l)
	lat95th="95.00th_lat="$lat95th
fi

result_str=$(grep "clat (usec)" $FIO_RESULT_FILE)
if [ -z "$result_str" ]; then
	result_str=$(grep "clat (msec)" $FIO_RESULT_FILE)
	#chang msec to usec
	avg_lat_str=$(echo $result_str | awk -F "," '{print $3}')
	lat=${avg_lat_str#*=}
	lat=$(echo $lat*1000|bc -l)
	avg_lat_str="avg=$lat"
else 
	avg_lat_str=$(echo $result_str | awk -F "," '{print $3}')
fi

result_str=$(grep "util=" $FIO_RESULT_FILE)
util_str=$(echo $result_str | awk -F "," '{print $5}')
echo $ip, $vmnum, $bs, $iodepth, $iops_str, $bw_str, $lat95th, $avg_lat_str, $util_str, $mode
