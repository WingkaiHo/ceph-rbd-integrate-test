#! /bin/bash

CONF_FILES=$(ls *.conf)

for conf in $CONF_FILES
do
	cat $conf | gnuplot
done
