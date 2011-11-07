#!/usr/bin/python

import csv
import sys
import pylab

filename = sys.argv[1]
ofilename = sys.argv[2]

csv_reader = csv.reader(open(filename, 'rb'), delimiter=',')
x = []
y1 = []
y2 = []
for row in csv_reader:
    x.append(float(row[0]))
    y1.append(int(row[1]))
    y2.append(int(row[2]))

pylab.title(filename)
pylab.xlabel("Temperature (C)")
pylab.ylabel("Ring oscillator frequency (counts)")
pylab.scatter(x, y1, marker='+', color="red", label="Channel 1")
pylab.scatter(x, y2, marker='+', color="blue", label="Channel 2")
pylab.legend()
pylab.savefig(ofilename)
#pylab.show()
