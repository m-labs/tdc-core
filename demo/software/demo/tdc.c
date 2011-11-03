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

#include "temperature.h"
#include "tdc.h"

static volatile struct TDC_WB *tdc = (void *)0xa0000000;

void rofreq()
{
    int val;
    int last;
    int t;
    
    /* reset into debug mode, so this will always work */
    tdc->DCTL = TDC_DCTL_REQ;
    tdc->CS = TDC_CS_RST;
    while(!(tdc->DCTL & TDC_DCTL_ACK));
    
    while(!readchar_nonblock()) {
        t = gettemp();
        printf("%d.%04d", t/16, (t%16)*625);
        do {
            tdc->FCC = TDC_FCC_ST;
            while(!(tdc->FCC & TDC_FCC_RDY));
            val = tdc->FCR;
            printf(",%d", val);
            last = tdc->CSEL & TDC_CSEL_LAST;
            tdc->CSEL = TDC_CSEL_NEXT;
        } while(!last);
        printf("\n");
    }
    
    tdc->DCTL = 0;
    tdc->CS = TDC_CS_RST;
}

#define TDC_RAW_COUNT 9

void calinfo()
{
    int channel;
    int i;
    int last;
    
    if(!(tdc->CS & TDC_CS_RDY)) {
        printf("Startup calibration not done\n");
        return;
    }
    tdc->DCTL = TDC_DCTL_REQ;
    while(!(tdc->DCTL & TDC_DCTL_ACK));
    
    /* go to first channel */
    while(!(tdc->CSEL & TDC_CSEL_LAST))
        tdc->CSEL = TDC_CSEL_NEXT;
    tdc->CSEL = TDC_CSEL_NEXT;
    
    channel = 0;
    do {
        printf("CHANNEL %d\n", channel);
        printf("HIST: ");
        for(i=0;i<(1 << TDC_RAW_COUNT);i++) {
            tdc->HISA = i;
            printf("%d,", tdc->HISD);
        }
        printf("\n");
        printf("LUT: ");
        for(i=0;i<(1 << TDC_RAW_COUNT);i++) {
            tdc->LUTA = i;
            printf("%d,", tdc->LUTD);
        }
        printf("\n\n");
        channel++;
        last = tdc->CSEL & TDC_CSEL_LAST;
        tdc->CSEL = TDC_CSEL_NEXT;
    } while(!last);
    
    tdc->DCTL = 0;
}

void mraw()
{
    if(!(tdc->CS & TDC_CS_RDY)) {
        printf("Startup calibration not done\n");
        return;
    }
    tdc->EIC_IER = TDC_EIC_IER_IE0;
    
    while(1) {
        while(!(tdc->EIC_ISR & TDC_EIC_ISR_IE0)) {
            if(readchar_nonblock()) return;
        }
        printf("%d[%d]\n", tdc->RAW0, tdc->POL & 0x01);
        tdc->EIC_ISR = TDC_EIC_ISR_IE0;
    }
}

#define CSV

void diff()
{
    int pol0, pol1;
    unsigned int rts0, rts1;
    unsigned int ts0, ts1;
#ifndef CSV
    int diff;
    int rdiff;
#endif
    
    if(!(tdc->CS & TDC_CS_RDY)) {
        printf("Startup calibration not done\n");
        return;
    }
    tdc->EIC_IER = TDC_EIC_IER_IE0|TDC_EIC_IER_IE1;
    while(1) {
        while((tdc->EIC_ISR & (TDC_EIC_ISR_IE0|TDC_EIC_IER_IE1)) != (TDC_EIC_ISR_IE0|TDC_EIC_IER_IE1)) {
            if(readchar_nonblock()) return;
        }
        pol0 = pol1 = tdc->POL;
        pol0 = !!(pol0 & 0x01);
        pol1 = !!(pol1 & 0x02);
        ts0 = tdc->MESL0;
        ts1 = tdc->MESL1;
        rts0 = tdc->RAW0;
        rts1 = tdc->RAW1;
        #ifdef CSV
        printf("%u,%u,%u,%u,%u,%u\n", pol0, rts0, ts0, pol1, rts1, ts1);
        #else
        diff = ts0 - ts1;
        if(diff < 0)
            diff = -diff;
        rdiff = rts0 - rts1;
        if(rdiff < 0)
            rdiff = -rdiff;
        printf("0: %dps [%d/%d]  1: %dps [%d/%d]  diff: %dps [%d]\n", 
            ts0*977/1000, rts0, pol0,
            ts1*977/1000, rts1, pol1,
            diff*977/1000, rdiff);
        #endif
        if(pol0 != pol1)
            printf("Inconsistent polarities!\n");
        tdc->EIC_ISR = TDC_EIC_ISR_IE0|TDC_EIC_ISR_IE1;
    }
}
