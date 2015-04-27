/*
*  fbmode.c
*
*  Switch console between text/graphics mode
*
*  (c) 2007 Softerra
*  Author: h2o <root@lx2>
*
*/

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/kd.h>

unsigned long mode;

void usage(FILE* stream, char* progname)
{
	fprintf(stream, "\n%s version 0.33 %s, %s\n\n", progname, __DATE__, __TIME__);
	fprintf(stream, "-t switch console to text\n");
	fprintf(stream, "-g switch console to graphics\n");
	fprintf(stream, "-h get some help\n");
	fprintf(stream, "Example usage\n");
	fprintf(stream, "%s -g\n\n", progname);
	exit(1);
}

int parse_params(int argc, char *argv[])
{
	int next_option;

	do
	{
		next_option = getopt(argc, argv, "tgh");
		switch (next_option)
		{
		case 't':
			mode = KD_TEXT;
			break;
		case 'g':
			mode = KD_GRAPHICS;
			break;
		case 'h':
			usage(stderr, argv[0]);
			break;
		}
	} while (next_option != -1);
		
	return 0;
}

int main(int argc, char *argv[])
{
	int tty;
	int ret = 0;

	mode = KD_TEXT;
	parse_params(argc, argv);

	/* open tty, to switch between modes */
	tty = open("/dev/tty0", O_WRONLY);
	if(tty < 0) {
        	printf("Error: can't open /dev/tty0\n");
	} else {
		/* mode switching */
		ret = ioctl(tty, KDSETMODE, mode);
		if ( ret == -1) {
			printf("Error: can't set specified mode\n");
		}
		close(tty);
	}
	return ret;
}
