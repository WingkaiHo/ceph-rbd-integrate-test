#!/bin/bash

CURR_PATH=$(cd "$(dirname "$0")"; pwd)

USER=root
PASSWORD=engine

while getopts "l:p:h" arg
do
	case $arg in
		l)
			AUTO_LOGIN_LIST=$OPTARG
			;;
		p)
			PASSWORD=$OPTARG
			;;
		?)
		echo "-l assign to set auto login host list."
		echo "-p assign password auto login host."
		exit 1
		;;
	esac
done


if [ ! -e $AUTO_LOGIN_LIST ]; then
	echo "the host list path is invalid!"
	exit 1
fi

HOSTS_COUNT=0
while read -r line
do
	hosts[$HOSTS_COUNT]=$line
	((HOSTS_COUNT++))
done < $AUTO_LOGIN_LIST

for ((i=0; i<$HOSTS_COUNT; i++))
do
	expect -c "set timeout -1;
	spawn ssh-copy-id $USER@${hosts[$i]};
	expect {
	*(yes/no)* {send -- yes\r;exp_continue;}
	*assword:* {send -- $PASSWORD\r\r;exp_continue;}
	eof        {exit 0;}
	}";
done
