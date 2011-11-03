#include <hw/sysctl.h>

#include "udelay.h"

void udelay(int usec)
{
    int limit;
    
    limit = usec*125;
    CSR_TIMER0_CONTROL = 0;
    CSR_TIMER0_COUNTER = 0;
    CSR_TIMER0_CONTROL = TIMER_ENABLE;
    while(CSR_TIMER0_COUNTER < limit);
}
