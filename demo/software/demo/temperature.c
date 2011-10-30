/*
 * 1-wire temperature sensor access
 *
 * Copyright (C) 2011 CERN
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <hw/sysctl.h>
#include <hw/gpio.h>

#include "temperature.h"

static void udelay(int usec)
{
    int limit;
    
    limit = usec*125;
    CSR_TIMER0_CONTROL = 0;
    CSR_TIMER0_COUNTER = 0;
    CSR_TIMER0_CONTROL = TIMER_ENABLE;
    while(CSR_TIMER0_COUNTER < limit);
}

static int reset_1w()
{
    int ok;
    
    CSR_GPIO_OUT |= GPIO_1W_DRIVELOW;
    udelay(500);
    CSR_GPIO_OUT &= ~GPIO_1W_DRIVELOW;
    udelay(65);
    ok = !(CSR_GPIO_IN & GPIO_1W);
    udelay(500);
    return ok;
}

static void txbyte_1w(unsigned char b)
{
    int i;
    
    for(i=0;i<8;i++) {
        if(b & (1 << i)) {
            CSR_GPIO_OUT |= GPIO_1W_DRIVELOW;
            udelay(10);
            CSR_GPIO_OUT &= ~GPIO_1W_DRIVELOW;
            udelay(90);
        } else {
            CSR_GPIO_OUT |= GPIO_1W_DRIVELOW;
            udelay(65);
            CSR_GPIO_OUT &= ~GPIO_1W_DRIVELOW;
            udelay(35);
        }
    }
}

static int rxbit_1w()
{
    int r;
    
    CSR_GPIO_OUT |= GPIO_1W_DRIVELOW;
    udelay(5);
    CSR_GPIO_OUT &= ~GPIO_1W_DRIVELOW;
    udelay(5);
    r = CSR_GPIO_IN & GPIO_1W;
    udelay(90);
    return r;
}

static unsigned char rxbyte_1w()
{
    unsigned char b;
    int i;
    
    b = 0;
    for(i=0;i<8;i++) {
        if(rxbit_1w())
            b |= (1 << i);
    }
    return b;
}

int gettemp()
{
    unsigned char sp[9];
    int i;
    
    if(!reset_1w()) {
        printf("1W reset failed (1)\n");
        return -1000;
    }
    txbyte_1w(0xcc); /* skip ROM */
    txbyte_1w(0x44); /* convert temperature */
    while(!rxbyte_1w()); /* wait for end of conversion */
    if(!reset_1w()) {
        printf("1W reset failed (2)\n");
        return -1000;
    }
    txbyte_1w(0xcc); /* skip ROM */
    txbyte_1w(0xbe); /* read scratchpad */
    for(i=0;i<9;i++)
        sp[i] = rxbyte_1w();
    return (((short)sp[1]) << 8) | ((short)sp[0]);
}

void temp()
{
    int t;
    
    t = gettemp();
    printf("%d.%04dC\n", t/16, (t%16)*625);
}
