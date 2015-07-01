#!/bin/bash
declare -i x=10
declare -i y=12
declare -i z=0
z=$(( x + y ))
echo "$x + $y = $z"

#Lets add a different value character 'a'
x=a
z=$(( $x + $y ))
echo "$x + $y = $z"
