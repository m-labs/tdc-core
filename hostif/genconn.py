#!/usr/bin/python

nchan = 8

for i in range(0,nchan):
    print "tdc_desh%d_o => wbg_des(%d downto %d)," % (i, i*64+63, i*64+32)
    print "tdc_desl%d_o => wbg_des(%d downto %d)," % (i, i*64+31, i*64)

for i in range(0,nchan):
    print "tdc_raw%d_i => wbg_raw(%d downto %d)," % (i, i*32+31, i*32)
    print "tdc_mesh%d_i => wbg_mes(%d downto %d)," % (i, i*64+63, i*64+32)
    print "tdc_mesl%d_i => wbg_mes(%d downto %d)," % (i, i*64+31, i*64)

for i in range(0,nchan):
    print "irq_ie%d_i => wbg_ie(%d)," % (i, i)
