/*
 * DAC5578 bit-banging driver
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
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

/* WARNING/FIXME: The I2C functions clear the other GPIO bits! */

#include <stdio.h>

#include <hw/sysctl.h>
#include <hw/gpio.h>

#include "udelay.h"

static int i2c_started;

static int i2c_init()
{
	unsigned int timeout;

	i2c_started = 0;
	CSR_GPIO_OUT = GPIO_I2C_SDC;
	/* Check the I2C bus is ready */
	timeout = 2000;
	while((timeout > 0) && (!(CSR_GPIO_IN & GPIO_I2C_SDAIN))) timeout--;

	return timeout;
}

static void i2c_delay()
{
	udelay(20);
}

/* I2C bit-banging functions from http://en.wikipedia.org/wiki/I2c */
static unsigned int i2c_read_bit()
{
	unsigned int bit;

	/* Let the slave drive data */
	CSR_GPIO_OUT = 0;
	i2c_delay();
	CSR_GPIO_OUT = GPIO_I2C_SDC;
	i2c_delay();
	bit = CSR_GPIO_IN & GPIO_I2C_SDAIN;
	i2c_delay();
	CSR_GPIO_OUT = 0;
	return bit;
}

static void i2c_write_bit(unsigned int bit)
{
	if(bit) {
		CSR_GPIO_OUT = GPIO_I2C_SDAOE|GPIO_I2C_SDAOUT;
	} else {
		CSR_GPIO_OUT = GPIO_I2C_SDAOE;
	}
	i2c_delay();
	/* Clock stretching */
	CSR_GPIO_OUT |= GPIO_I2C_SDC;
	i2c_delay();
	CSR_GPIO_OUT &= ~GPIO_I2C_SDC;
}

static void i2c_start_cond()
{
	if(i2c_started) {
		/* set SDA to 1 */
		CSR_GPIO_OUT = GPIO_I2C_SDAOE|GPIO_I2C_SDAOUT;
		i2c_delay();
		CSR_GPIO_OUT |= GPIO_I2C_SDC;
	}
	/* SCL is high, set SDA from 1 to 0 */
	CSR_GPIO_OUT = GPIO_I2C_SDAOE|GPIO_I2C_SDC;
	i2c_delay();
	CSR_GPIO_OUT = GPIO_I2C_SDAOE;
	i2c_started = 1;
}

static void i2c_stop_cond()
{
	/* set SDA to 0 */
	CSR_GPIO_OUT = GPIO_I2C_SDAOE;
	i2c_delay();
	/* Clock stretching */
	CSR_GPIO_OUT = GPIO_I2C_SDAOE|GPIO_I2C_SDC;
	/* SCL is high, set SDA from 0 to 1 */
	CSR_GPIO_OUT = GPIO_I2C_SDC;
	i2c_delay();
	i2c_started = 0;
}

static unsigned int i2c_write(unsigned char byte)
{
	unsigned int bit;
	unsigned int ack;

	for(bit = 0; bit < 8; bit++) {
		i2c_write_bit(byte & 0x80);
		byte <<= 1;
	}
	ack = !i2c_read_bit();
	return ack;
}

static unsigned char i2c_read(int ack)
{
	unsigned char byte = 0;
	unsigned int bit;

	for(bit = 0; bit < 8; bit++) {
		byte <<= 1;
		byte |= i2c_read_bit();
	}
	i2c_write_bit(!ack);
	return byte;
}

void set_dac_level(int level)
{
	if(!i2c_init()) {
		printf("I2C init failed\n");
		return;
	}
	i2c_start_cond();
	if(!i2c_write(0x50))
		printf("DAC not detected\n");
	i2c_write(0x2f);
	i2c_write((level & 0xff0) >> 4);
	i2c_write((level & 0x00f) << 4);
	i2c_stop_cond();
}
