#!/bin/bash
readonly DATA=/var/www/html/index.php
echo $DATA
unset DATA
DATA=/home/sahil
echo $DATA
