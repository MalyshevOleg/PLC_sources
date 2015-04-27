/* Copyright (c) 2013, Promwad. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301, USA.
 */

#include <termios.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <stdio.h>

/* 
* Set or Clear RTS modem control line 
* 
* Note: TIOCMSET and TIOCMGET are POSIX 
* 
* the same things: 
* 
* TIOCMODS and TIOCMODG are BSD (4.3 ?) 
* MCSETA and MCGETA are HPUX 
*/ 
void 
setrts(int fd, int on) 
{ 
	int controlbits; 
	printf("RTS: %d\n", on);
	ioctl(fd, TIOCMGET, &controlbits); 
	if (on) { 
		controlbits |= TIOCM_RTS; 
	} else { 
		controlbits &= ~TIOCM_RTS; 
	} 
	ioctl(fd, TIOCMSET, &controlbits); 
} 

/* 
* Set or Clear DTR modem control line 
* 
* Note: TIOCMBIS: CoMmand BIt Set 
* TIOCMBIC: CoMmand BIt Clear 
* 
*/ 
void 
setdtr (int fd, int on) 
{ 
	int controlbits = TIOCM_DTR; 
	printf("DTR: %d\n", on);
	ioctl(fd, (on ? TIOCMBIS : TIOCMBIC), &controlbits); 
}

void usage(void) 
{
	printf("usage: toggle <uart port> <rts> <dtr>\n");
}

int main(int argc, char **argv) 
{
	int h, status;

	if (argc < 4) {
		usage();
		return 0;
	}

	h = open(argv[1], O_RDWR);
	if (h < 0) {
		perror("open failed");
		return 1;
	}

	setrts(h, strcmp(argv[2], "on") ? 0 : 1);
	setdtr(h, strcmp(argv[3], "on") ? 0 : 1);

	while (1) {
		if (ioctl(h, TIOCMGET, &status) == -1)
			printf("TIOCMGET failed\n");
		else {
			if (status & TIOCM_DTR)
				printf("DTR: 1, ");
			else
				printf("DTR: 0, ");
			
			if (status & TIOCM_RTS)
				printf("RTS: 1, ");
			else
				printf("RTS: 0, ");

			if (status & TIOCM_CTS)
				printf("CTS: 1, ");
			else
				printf("CTS: 0, ");
			
			if (status & TIOCM_CAR)
				printf("CAR: 1, ");
			else
				printf("CAR: 0, ");
			
			if (status & TIOCM_RNG)
				printf("RNG: 1, ");
			else
				printf("RNG: 0, ");
			
			if (status & TIOCM_DSR)
				printf("DSR: 1\n");
			else
				printf("DSR: 0\n");
		}
		
		sleep(1);
	}
		
	close(h);
	
	return 0;
}
