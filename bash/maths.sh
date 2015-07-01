#!/bin/bash
read -p "Enter two numbers: " x y
echo ""
read -t 3
echo "Thanks for providing numbers, Now what do you want?"
add(){
z=$(( x + y ))
echo "$x + $y = $z"}
read -t 3
sub(){
z=$(( x - y ))
echo "$X - $y = $z"
add
sub
