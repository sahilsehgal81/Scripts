#!/bin/bash
read -p "Enter the password of your Username: " pass
if test "$pass" == "root"
then
 echo ""
# echo "====================================="
 read -t 3
 echo "You have entered the password $pass, which is up to the mark."
else
# echo "#####################################"
 echo ""
 read -t 3
 echo "You have entered the password $pass, whcih Doesn't meet at all."
fi
