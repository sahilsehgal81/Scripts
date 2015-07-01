#!/usr/bin/python

import sys
import os

file_name = raw_input('Enter filename: ')
if len(file_name) == 0:
 print 'Next time please make sure to enter something'
 sys.exit()
try:
 file = open(file_name, 'r')
except IOError:
 print "There is issue reading the file"
 sys.exit()
file_text = file.read()
file.close()
print file_text
