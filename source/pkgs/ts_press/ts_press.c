#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/fcntl.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <getopt.h>
#include <sys/poll.h>
#include <string.h>

#include "tslib.h"

const int nonblock = 1;

void die(const char *msg)
{
	perror(msg);
	exit(1);
}

struct tsdev *ts_init()
{
	char *tsdevice=NULL;
	struct tsdev *ts;
        if( (tsdevice = getenv("TSLIB_TSDEVICE")) != NULL ) {
                ts = ts_open(tsdevice, nonblock);
        } else {
#ifdef USE_INPUT_API
                ts = ts_open("/dev/input/event0", nonblock);
#else
                ts = ts_open("/dev/touchscreen/ucb1x00", nonblock);
#endif /* USE_INPUT_API */
        }

	if (!ts) {
		die("ts_open");
	}

	if (ts_config(ts)) {
		die("ts_config");
	}
	return ts;
}

void output(int is_long, int show_pos, int x, int y)
{
	printf("%s", is_long ? "long" : "short");
	if (show_pos) {
		printf(":%u:%u", x, y);
	}
	printf("\n");
}

int is_long(struct timeval *tv, int long_time)
{
	return (tv->tv_sec * 1000 + tv->tv_usec / 1000) > (long_time * 1000);
}

int get_timeout(struct timeval *tv_fin)
{
	struct timeval tv, tv_delta;
	gettimeofday(&tv, 0);
	if (timercmp(&tv, tv_fin, >)) {
		return 0;
	}
	timersub(tv_fin, &tv, &tv_delta);
	return tv_delta.tv_sec * 1000 + tv_delta.tv_usec / 1000;
}

int main(int argc, char **argv)
{
	int delay = 3;
	int show_pos = 0;
	int long_time = 1;

	int state = 0;
	int x, y;
	int ret;
	int timeout;
	struct ts_sample samp;
	struct timeval tv_fin, tv_tmp, tv;
	struct tsdev *ts;

	struct pollfd fds;

	while (1) {
		x = getopt(argc, argv, "d:pl:");
		if (x < 0) {
			break;
		}
		switch (x) {
		case 'd':
			delay = strtoul(optarg, 0, 0);
			if (delay <= 0) {
				delay = 1;
			}
			break;
		case 'p':
			show_pos = 1;
			break;
		case 'l':
			long_time = strtoul(optarg, 0, 0);
			if (long_time <= 0) {
				long_time = 1;
			}
			break;
		}
 	}

	ts = ts_init();

	gettimeofday(&tv, 0);
	tv_tmp.tv_sec = delay;
	tv_tmp.tv_usec = 0;
	timeradd(&tv, &tv_tmp, &tv_fin);

  	memset(&fds, 0, sizeof(fds));
  	fds.fd = *(int *)ts;		// undocumented stuff: fd is first member of tsdev - type int
  	fds.events = POLLIN;
		
	for (;;) {
		ret = poll(&fds, 1, get_timeout(&tv_fin));
		if (ret < 0) {
			die("poll error");
                }
		if (ret == 0) {
			break;
		}
		ts_read(ts, &samp, 1);
		if ((samp.pressure > 0) != state) {
			state = samp.pressure > 0;
			if (state != 0) {
				tv = samp.tv;
				x = samp.x;
				y = samp.y;
			} else {
				timersub(&samp.tv, &tv, &tv_tmp);
				output(is_long(&tv_tmp, long_time), show_pos, x, y);
				return 0;
			}
		}
	}

	if (state != 0) {
		for (;;) {
			ret = poll(&fds, 1, -1);
			if (ret < 0) {
				die("poll error");
                	}
			if (ret == 0) {
				continue;
			}
			ts_read(ts, &samp, 1);
			if (samp.pressure <= 0) {
				break;
			}
			x = samp.x;
			y = samp.y;
		}
		output(1, show_pos, x, y);
	}

	return !state;
}
