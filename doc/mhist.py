#!/usr/bin/python

import csv
import sys
import pylab

filename = sys.argv[1]
ofilename = sys.argv[2]
polarity = sys.argv[3]
fit = (len(sys.argv) > 4) and (sys.argv[4] == "fit")

csv_reader = csv.reader(open(filename, 'rb'), delimiter=',')
data = []
for row in csv_reader:
    if (polarity.find(row[0]) != -1):
        data.append((float(row[5])-float(row[2]))*8000.0/2.0**13.0)

m, M = min(data), max(data)
mu = pylab.mean(data)
sigma = pylab.std(data)
s = "%s Polarity: %s Samples: %d\nMean: %f Std: %f P/p: %f" % (filename, polarity, len(data), mu, sigma, M-m)
pylab.title(s)
grid = pylab.linspace(m, M, 100)
if fit:
    densityvalues = pylab.normpdf(grid, mu, sigma)
    pylab.plot(grid, densityvalues, 'r-')
pylab.hist(data, 40, normed=True)
pylab.xlabel("Time difference (ps)")
pylab.ylabel("Density")
pylab.savefig(ofilename)
#pylab.show()
