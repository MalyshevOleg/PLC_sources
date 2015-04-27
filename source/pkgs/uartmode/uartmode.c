#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <string.h>
#include <linux/serial.h>
#include <asm/ioctls.h>

void usage(void) 
{
  printf("usage: uartmode <-232|-485> <uart port>\n");
}

int main(int argc, char **argv) 
{
  int h;
  struct serial_rs485 rs485conf;

  if (argc < 2) {
    usage();
    return 0;
  }

  if (argc < 3) {
    h = open(argv[1], O_RDWR);
    if (h < 0) {
      perror("open failed");
      return 1;
    }
    if (ioctl(h, TIOCGRS485, &rs485conf)) {
      perror("ioctl failed");
      return 1;
    }
    printf("%s: %s\n", argv[1], (rs485conf.flags & SER_RS485_ENABLED) ? "rs485" : "rs232");
  } else {
    if (strcmp(argv[1], "-232") && strcmp(argv[1], "-485")) {
      usage();
      return 0;
    }
    h = open(argv[2], O_RDWR);
    if (h < 0) {
      perror("open failed");
      return 1;
    }
    memset(&rs485conf, 0, sizeof(rs485conf));
    if (strcmp(argv[1], "-485") == 0) {
      rs485conf.flags = SER_RS485_ENABLED;
    }
    if (ioctl(h, TIOCSRS485, &rs485conf)) {
      perror("ioctl failed");
      return 1;
    }
  }
  close(h);
  return 0;
}