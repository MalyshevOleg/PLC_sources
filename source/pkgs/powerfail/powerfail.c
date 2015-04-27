/*
 *  Copyright (c) 2013 Viktar Palstsiuk, Promwad
 *
 *  Powerfail daemon
 */

/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or 
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <linux/input.h>
#include <time.h>

#define FILE_PATH	"/dev/input/event1"
#define PWRSTAT		"/var/run/powerstatus"

long timevaldiff(struct timeval *starttime, struct timeval *finishtime)
{
	long msec;
	msec = (finishtime->tv_sec - starttime->tv_sec) * 1000;
	msec += (finishtime->tv_usec - starttime->tv_usec) / 1000;
	return msec;
}

void powerfail(int failure_mode)
{
	int fd;
	struct timeval start, tv;
	long msec;

	/* Create an info file for init. */
	unlink(PWRSTAT);
	if ((fd = open(PWRSTAT, O_CREAT | O_WRONLY, 0644)) >= 0) {
		if (failure_mode) {
			/* Problem */
			write(fd, "FAIL\n", 5);
		} else {
			/* No problem */
			write(fd, "OK\n", 3);
		}
		close(fd);
	}

	kill(1, SIGPWR);
#if 0
	gettimeofday(&start, NULL);
	while(1) {
		gettimeofday(&tv, NULL);
		msec = timevaldiff(&start, &tv);
		printf("%u ms\n", msec);
		usleep(5000);
	}
#endif
}

int main()
{
	size_t file;
	const char *str = FILE_PATH;
	struct input_event event[64];
	size_t reader;

	if((file = open(str, O_RDWR)) < 0) {
		printf("ERROR:File can not open\n");
		exit(0);
	}

	/* Drop into the background, close stdio, detach from terminal. */
	daemon(0, 0);

	while(reader = read(file, event, sizeof(struct input_event) * 64)) {
		if((event[0].type == EV_KEY) && (event[0].code == BTN_DEAD)) {
			powerfail(!event[0].value);
		}
	}

	close(file);
	return 0;
}
