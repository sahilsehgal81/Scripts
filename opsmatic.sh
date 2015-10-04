#!/bin/bash

set -e

OUTPUT_FILE=$1

if [ "x$OUTPUT_FILE" = "x" ]; then
    echo "You must supply an output file as the first argument"
    exit 1;
fi

TMPFILE=`mktemp -t opsmatic_file_format_XXXXXXXXXXX`

# header
echo "{\"files\":[" > $TMPFILE

FIRST=1
while read line
do
    if [ "x$FIRST" != "x1" ]; then
        echo "," >> $TMPFILE
    fi

    FIRST=0
    echo -n "    {\"path\":\"${line}\"}" >> $TMPFILE
done < /dev/stdin

# footer
echo "" >> $TMPFILE
echo "]}" >> $TMPFILE

cp $TMPFILE $OUTPUT_FILE
rm -f $TMPFILE
