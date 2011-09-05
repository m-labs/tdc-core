/*
 * Milkymist VJ SoC (Software)
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <console.h>
#include <uart.h>
#include <system.h>
#include <board.h>
#include <crc.h>
#include <sfl.h>

#include "boot.h"

extern const struct board_desc *brd_desc;

/*
 * HACK: by defining this function as not inlinable, GCC will automatically
 * put the values we want into the good registers because it has to respect
 * the LM32 calling conventions.
 */
static void __attribute__((noinline)) __attribute__((noreturn)) boot(unsigned int r1, unsigned int r2, unsigned int r3, unsigned int addr)
{
	asm volatile( /* Invalidate instruction cache */
		"wcsr ICC, r0\n"
		"nop\n"
		"nop\n"
		"nop\n"
		"nop\n"
		"call r4\n"
	);
}

/* Note that we do not use the hw timer so that this function works
 * even if the system controller has been disabled at synthesis.
 */
static int check_ack()
{
	int timeout;
	int recognized;
	static const char str[SFL_MAGIC_LEN] = SFL_MAGIC_ACK;
	
	timeout = 4500000;
	recognized = 0;
	while(timeout > 0) {
		if(readchar_nonblock()) {
			char c;
			c = readchar();
			if(c == str[recognized]) {
				recognized++;
				if(recognized == SFL_MAGIC_LEN)
					return 1;
			} else {
				if(c == str[0])
					recognized = 1;
				else
					recognized = 0;
			}
		}
		timeout--;
	}
	return 0;
}

#define MAX_FAILED 5

void serialboot()
{
	struct sfl_frame frame;
	int failed;
	unsigned int cmdline_adr, initrdstart_adr, initrdend_adr;
	
	printf("I: Attempting serial firmware loading\n");
	putsnonl(SFL_MAGIC_REQ);
	if(!check_ack()) {
		printf("E: Timeout\n");
		return;
	}
	
	failed = 0;
	cmdline_adr = initrdstart_adr = initrdend_adr = 0;
	while(1) {
		int i;
		int actualcrc;
		int goodcrc;
		
		/* Grab one frame */
		frame.length = readchar();
		frame.crc[0] = readchar();
		frame.crc[1] = readchar();
		frame.cmd = readchar();
		for(i=0;i<frame.length;i++)
			frame.payload[i] = readchar();
		
		/* Check CRC */
		actualcrc = ((int)frame.crc[0] << 8)|(int)frame.crc[1];
		goodcrc = crc16(&frame.cmd, frame.length+1);
		if(actualcrc != goodcrc) {
			failed++;
			if(failed == MAX_FAILED) {
				printf("E: Too many consecutive errors, aborting");
				return;
			}
			writechar(SFL_ACK_CRCERROR);
			continue;
		}
		
		/* CRC OK */
		switch(frame.cmd) {
			case SFL_CMD_ABORT:
				failed = 0;
				writechar(SFL_ACK_SUCCESS);
				return;
			case SFL_CMD_LOAD: {
				char *writepointer;
				
				failed = 0;
				writepointer = (char *)(
					 ((unsigned int)frame.payload[0] << 24)
					|((unsigned int)frame.payload[1] << 16)
					|((unsigned int)frame.payload[2] << 8)
					|((unsigned int)frame.payload[3] << 0));
				for(i=4;i<frame.length;i++)
					*(writepointer++) = frame.payload[i];
				writechar(SFL_ACK_SUCCESS);
				break;
			}
			case SFL_CMD_JUMP: {
				unsigned int addr;
				
				failed = 0;
				addr =  ((unsigned int)frame.payload[0] << 24)
					|((unsigned int)frame.payload[1] << 16)
					|((unsigned int)frame.payload[2] << 8)
					|((unsigned int)frame.payload[3] << 0);
				writechar(SFL_ACK_SUCCESS);
				boot(cmdline_adr, initrdstart_adr, initrdend_adr, addr);
				break;
			}
			case SFL_CMD_CMDLINE:
				failed = 0;
				cmdline_adr =  ((unsigned int)frame.payload[0] << 24)
					      |((unsigned int)frame.payload[1] << 16)
					      |((unsigned int)frame.payload[2] << 8)
					      |((unsigned int)frame.payload[3] << 0);
				writechar(SFL_ACK_SUCCESS);
				break;
			case SFL_CMD_INITRDSTART:
				failed = 0;
				initrdstart_adr =  ((unsigned int)frame.payload[0] << 24)
					          |((unsigned int)frame.payload[1] << 16)
					          |((unsigned int)frame.payload[2] << 8)
					          |((unsigned int)frame.payload[3] << 0);
				writechar(SFL_ACK_SUCCESS);
				break;
			case SFL_CMD_INITRDEND:
				failed = 0;
				initrdend_adr =  ((unsigned int)frame.payload[0] << 24)
					        |((unsigned int)frame.payload[1] << 16)
					        |((unsigned int)frame.payload[2] << 8)
					        |((unsigned int)frame.payload[3] << 0);
				writechar(SFL_ACK_SUCCESS);
				break;
			default:
				failed++;
				if(failed == MAX_FAILED) {
					printf("E: Too many consecutive errors, aborting");
					return;
				}
				writechar(SFL_ACK_UNKNOWN);
				break;
		}
	}
}
