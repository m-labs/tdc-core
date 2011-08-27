#!/usr/bin/python

nchan = 8

print "peripheral {"
print "    name = \"TDC\";"
print "    description = \"Time to digital converter.\";"
print "    hdl_entity = \"tdc_wb\";"
print "    prefix = \"tdc\";"

# Registers

print """
    reg {
        name = "Control and status";
        description = "Control and status.";
        prefix = "cs";

        field {
            name = "Reset";
            prefix = "rst";
            type = MONOSTABLE;
        };
        field {
            name = "Ready";
            prefix = "rdy";
            type = BIT;
            access_bus = READ_ONLY;
            access_dev = WRITE_ONLY;
        };
    };
"""

for i in range(0,nchan):
    print "    reg {"
    print "        name = \"Deskew value for channel %d (high word)\";" % i
    print "        description = \"A constant value added to all measurements of channel %d.\";" % i
    print "        prefix = \"desh%d\";" % i
    print ""
    print "        field {"
    print "            name = \"High word value\";"
    print "            type = SLV;"
    print "            size = 32;"
    print "            access_bus = READ_WRITE;"
    print "            access_dev = READ_ONLY;"
    print "        };"
    print "    };"
    print ""
    print "    reg {"
    print "        name = \"Deskew value for channel %d (low word)\";" % i
    print "        description = \"A constant value added to all measurements of channel %d.\";" % i
    print "        prefix = \"desl%d\";" % i
    print ""
    print "        field {"
    print "            name = \"Low word value\";"
    print "            type = SLV;"
    print "            size = 32;"
    print "            access_bus = READ_WRITE;"
    print "            access_dev = READ_ONLY;"
    print "        };"
    print "    };"
    print ""

print "    reg {"
print "        name = \"Detected polarities\";"
print "        description = \"A bit vector representing the polarities (rising/falling edges) of the detected transitions.\";"
print "        prefix = \"pol\";"
print ""
print "        field {"
print "            name = \"Value\";"
print "            type = SLV;"
print "            size = %d;" % nchan
print "            access_bus = READ_ONLY;"
print "            access_dev = WRITE_ONLY;"
print "        };"
print "    };"
print ""

for i in range(0,nchan):
    print "    reg {"
    print "        name = \"Raw measured value for channel %d\";" % i
    print "        description = \"Raw encoded value from the fine delay line for channel %d.\";" % i
    print "        prefix = \"raw%d\";" % i
    print ""
    print "        field {"
    print "            name = \"Value\";"
    print "            type = SLV;"
    print "            size = 32;"
    print "            access_bus = READ_ONLY;"
    print "            access_dev = WRITE_ONLY;"
    print "        };"
    print "    };"
    print ""
    print "    reg {"
    print "        name = \"Fixed point measurement for channel %d (high word)\";" % i
    print "        description = \"Fully calibrated time stamp for channel %d.\";" % i
    print "        prefix = \"mesh%d\";" % i
    print ""
    print "        field {"
    print "            name = \"High word value\";"
    print "            type = SLV;"
    print "            size = 32;"
    print "            access_bus = READ_ONLY;"
    print "            access_dev = WRITE_ONLY;"
    print "        };"
    print "    };"
    print ""
    print "    reg {"
    print "        name = \"Fixed point measurement for channel %d (low word)\";" % i
    print "        description = \"Fully calibrated time stamp for channel %d.\";" % i
    print "        prefix = \"mesl%d\";" % i
    print ""
    print "        field {"
    print "            name = \"Low word value\";"
    print "            type = SLV;"
    print "            size = 32;"
    print "            access_bus = READ_ONLY;"
    print "            access_dev = WRITE_ONLY;"
    print "        };"
    print "    };"
    print ""

# Interrupts

for i in range(0,nchan):
    print "    irq {"
    print "        name = \"Event detection %d\";" % i
    print "        description = \"Interrupt triggered when the input signal changes state on channel %d.\";" % i
    print "        prefix = \"ie%d\";" % i
    print "        trigger = EDGE_RISING;"
    print "    };"
    print ""

print "    irq {"
print "        name = \"Startup calibration done\";"
print "        description = \"Interrupt triggered after the startup calibration is completed.\";"
print "        prefix = \"isc\";"
print "        trigger = EDGE_RISING;"
print "    };"
print ""

print "    irq {"
print "        name = \"Coarse counter overflow\";"
print "        description = \"Interrupt triggered when the coarse cycle counter overflows.\";"
print "        prefix = \"icc\";"
print "        trigger = EDGE_RISING;"
print "    };"
print ""

# Debug interface

print """
    reg {
        name = "Debug control";
        description = "Controls entering and leaving debug mode.";
        prefix = "dctl";

        field {
            name = "Freeze request";
            prefix = "req";
            type = BIT;
            access_bus = READ_WRITE;
            access_dev = READ_ONLY;
        };
        field {
            name = "Freeze acknowledgement";
            prefix = "ack";
            type = BIT;
            access_bus = READ_ONLY;
            access_dev = WRITE_ONLY;
        };
    };
    
    reg {
        name = "Channel selection";
        description = "Selects the channel the debug interface operates on.";
        prefix = "csel";

        field {
            name = "Switch to next channel";
            prefix = "next";
            type = MONOSTABLE;
        };
        field {
            name = "Last channel reached";
            prefix = "last";
            type = BIT;
            access_bus = READ_ONLY;
            access_dev = WRITE_ONLY;
        };
    };
    
    reg {
        name = "Calibration signal selection";
        description = "Forced switch to calibration signal.";
        prefix = "cal";

        field {
            name = "Calibration signal select";
            type = BIT;
            access_bus = READ_WRITE;
            access_dev = READ_ONLY;
        };
    };
    
    reg {
        name = "LUT read address";
        description = "LUT address to read when debugging.";
        prefix = "luta";

        field {
            name = "Address";
            type = SLV;
            size = 16;
            access_bus = READ_WRITE;
            access_dev = READ_ONLY;
        };
    };
    
    reg {
        name = "LUT read data";
        description = "LUT data readback for debugging.";
        prefix = "lutd";

        field {
            name = "Data";
            type = SLV;
            size = 32;
            access_bus = READ_ONLY;
            access_dev = WRITE_ONLY;
        };
    };
    
    reg {
        name = "Histogram read address";
        description = "Histogram address to read when debugging.";
        prefix = "hisa";

        field {
            name = "Address";
            type = SLV;
            size = 16;
            access_bus = READ_WRITE;
            access_dev = READ_ONLY;
        };
    };
    
    reg {
        name = "Histogram read data";
        description = "Histogram data readback for debugging.";
        prefix = "hisd";

        field {
            name = "Data";
            type = SLV;
            size = 32;
            access_bus = READ_ONLY;
            access_dev = WRITE_ONLY;
        };
    };
    
    reg {
        name = "Frequency counter control and status";
        description = "Starts the frequency counter and reports its status for debugging.";
        prefix = "fcc";

        field {
            name = "Measurement start";
            prefix = "st";
            type = MONOSTABLE;
        };
        field {
            name = "Measurement ready";
            prefix = "rdy";
            type = BIT;
            access_bus = READ_ONLY;
            access_dev = WRITE_ONLY;
        };
    };
    
    reg {
        name = "Frequency counter current value";
        description = "Reports the latest measurement result of the frequency counter for debugging.";
        prefix = "fcr";

        field {
            name = "Result";
            type = SLV;
            size = 32;
            access_bus = READ_ONLY;
            access_dev = WRITE_ONLY;
        };
    };
    
    reg {
        name = "Frequency counter stored value";
        description = "Reports the latest stored measurement result of the frequency counter for debugging.";
        prefix = "fcsr";

        field {
            name = "Result";
            type = SLV;
            size = 32;
            access_bus = READ_ONLY;
            access_dev = WRITE_ONLY;
        };
    };
"""

print "};"
