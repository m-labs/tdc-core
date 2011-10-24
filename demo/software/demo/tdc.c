/*
 * Time to Digital Converter demo routines
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
#include <uart.h>
#include <hw/tdc.h>

#include "tdc.h"

static volatile struct TDC_WB *tdc = (void *)0xa0000000;

void rofreq()
{
    int channel;
    int val;
    int last;
    
    /* reset into debug mode, so this will always work */
    tdc->DCTL = TDC_DCTL_REQ;
    tdc->CS = TDC_CS_RST;
    while(!(tdc->DCTL & TDC_DCTL_ACK));
    
    while(!readchar_nonblock()) {
        channel = 0;
        do {
            tdc->FCC = TDC_FCC_ST;
            while(!(tdc->FCC & TDC_FCC_RDY));
            val = tdc->FCR;
            printf("Channel %d: %d\n", channel, val);
            channel++;
            last = tdc->CSEL & TDC_CSEL_LAST;
            tdc->CSEL = TDC_CSEL_NEXT;
        } while(!last);
        printf("\n");
    }
}
