#!/usr/bin/python

import sys
import os
filename = raw_input("type filename here : ")
fo = open(filename, 'wb')
writing = "I am typing this SHIT in to the file okay\n"
write = fo.write(writing)
print "You have typed\n\n", writing
path = os.getcwd()
print "Location of file path is", path
fo.close()
print "Bye Bye!"
