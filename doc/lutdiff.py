#!/usr/bin/python

import sys
import pylab

filename1 = sys.argv[1]
filename2 = sys.argv[2]
ofilename = sys.argv[3]

def edata(filename):
    f1 = open(filename, 'r')
    return [int(x) for x in f1.readline().rstrip().split(',')]

data1 = edata(filename1)
data2 = edata(filename2)

data = [(x[0] - x[1])*8000.0/2.0**13.0 for x in zip(data1, data2)]
ssd = 0
peak = 0
for x in data:
    ssd += x**2.0
    if abs(x) > peak:
        peak = abs(x)

pylab.title("%s - %s\nSum of squares: %f Peak absolute: %f" % (filename1, filename2, ssd, peak))
pylab.bar(range(len(data)), data)
pylab.xlabel("LUT index")
pylab.ylabel("Difference (ps)")
pylab.savefig(ofilename)
#pylab.show()
