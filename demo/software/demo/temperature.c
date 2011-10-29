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

void temp()
{
    if(reset_1w())
        printf("1W reset OK\n");
    else
        printf("1W reset failed\n");
}
