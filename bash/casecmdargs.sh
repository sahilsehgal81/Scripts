#!/bin/bash
OPT=$1
FILE=$2

case $OPT in
	-e|-E) echo "Editing $FILE file..."
	read -t 3;
	[ -z $FILE ] && { echo "File name missing"; exit;} || vim $FILE;;
	-c|-C) echo "Display file name $FILE.."
	read -t 3;
	[ -z $FILE ] && { echo "File name missing"; exit;} || cat $FILE;;
	-d|-D) echo "Today is date $(date)";;
	*)
	echo "Bad Argument Entered!!"
	echo "Usage : Enter -e|-E for editing file"
	echo "Usage : Enter -c|-C for displaying file"
	echo "Usage : Enter -d|-D for displayng date"
esac
	
  
