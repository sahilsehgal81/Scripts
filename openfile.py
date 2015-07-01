#!/usr/bin/python

import sys
file_name = raw_input("Enter filename: ")
if len(file_name) == 0:
 print "Next time please enter something"
 sys.exit()
try:
 file = open(file_name, "r + w")
except IOError:
 print "There was an error writing file"
 sys.exit()
file_text = file.read()
file.close()
print file_text
