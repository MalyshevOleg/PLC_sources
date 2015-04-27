#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h> 
#include <getopt.h>
#include <poll.h>
#include <errno.h>
#include <syslog.h>
#include <sys/select.h>
#include <stdarg.h>
#include <time.h>

#define USE_SYSLOG   0
/*#define DEBUG        0 */

#define ERR_OPTIONS   1
#define ERR_NET_INIT  2
#define ERR_NET_EXCH  3

typedef unsigned char u_8;
typedef unsigned short u_16;
typedef unsigned int u_32;

static size_t clnt_total_tx = 0;
static size_t clnt_total_rx = 0;
static size_t srv_total_tx = 0;
static size_t srv_total_rx = 0;

void log_prefix(int type)
{
  struct tm tm;
  time_t tt;
  const char *type_str;

  tt = time(0);
  localtime_r(&tt, &tm);

  switch (type) { 
    default:
    case LOG_INFO:
      type_str = "info";
      break;
    case LOG_ERR:
      type_str = "error";
      break;
    case LOG_EMERG:
      type_str = "emerg";
      break;
    case LOG_ALERT:
      type_str = "alert";
      break;
    case LOG_CRIT:
      type_str = "crit";
      break;
    case LOG_WARNING  :
      type_str = "warning";
      break;
    case LOG_NOTICE:
      type_str = "notice";
      break;
    case LOG_DEBUG:
      type_str = "debug";
      break;
  }
  fprintf(stderr, "%04u/%02u/%02u %+2u:%02u:%02u %s: ", tm.tm_year + 1900, tm.tm_mon, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec, type_str);
}

void slogv(int type, const char *format, va_list va)
{
#if defined(USE_SYSLOG) && USE_SYSLOG
  static int log_opened = 0;
  
  if (!log_opened) {
    openlog("net_ids", LOG_PID | LOG_PERROR, LOG_USER);
    log_opened = 1;
  }
  vsyslog(type, format, va);
#if defined(DEBUG) && DEBUG
  vfprintf(stderr, format, va);
#endif
#else
  log_prefix(type);
  vfprintf(stderr, format, va);
#endif
}

void slog(int type, const char *format, ...)
{
  va_list args;
  va_start(args, format);
  slogv(type, format, args);
  va_end(args);
}

void die(int err, const char *format, ...)
{
  va_list args;
  va_start(args, format);

  if (err <= 0) {
    err = -err;
    slogv(err == 0 ? LOG_NOTICE : LOG_ERR, format, args);
    if (err == 0 || err == ERR_NET_EXCH) {
      slog(LOG_INFO, "server: tx bytes=%zu, rx bytes=%zu\n", srv_total_tx, srv_total_rx);
      slog(LOG_INFO, "client: tx bytes=%zu, rx bytes=%zu\n", clnt_total_tx, clnt_total_rx);
    }
  } else {
    log_prefix(LOG_ERR);
    vfprintf(stderr, format, args);
  }
  va_end(args);
  exit(err);
}

static inline unsigned char* store_data(u_8 *dst, const u_8 *src, size_t sz, int do_pack)
{
  u_8 hb;
  size_t p;

  if (do_pack) {
    for (p = 0, hb = 0; p < sz; ++p) {
      hb = (hb << 1) | ((*src & 0x80) >> 7);
      *dst++ = *src++ | 0x80;
      if ((p % 7) == 6) {
        *dst++ = hb | 0x80;
        hb = 0;
      }
    }
    if ((p % 7) != 6) {
      hb <<= 7 - (p % 7);
      *dst++ = hb | 0x80;
    }
  } else {
    memcpy(dst, src, sz);
    dst += sz;
  }
  return dst;
}

static void hexdump(const u_8 *ptr, size_t sz)
{
  size_t i;

  char *buf = alloca(sz * 2 + 1);
  char *p;

  for (i = 0, p = buf; i < sz; ++i) {
    sprintf(p, "%02x", ptr[i]);
    p += 2;
  }
  slog(LOG_DEBUG, "%s\n", buf);
}

/*#define PYRAMIDA_PACKED_SIZE(x) (((x) / 7) * 8 + ((x) % 7) + (((x) % 7) != 0))*/

size_t get_server_reply(u_32 id, u_8 *buf)
{
  u_8 rq[16] = { 0x0f, 0x0, 0x0, 0xfd, 0x0, 0x0, 0x0, 0x0, 0x25, 0x12, 0x10, 0x0, 0x0, 0x04 };
  u_16 crc;
  u_8 pyr_head[] = { 0x02, 0xaa, 0xaa };
  u_8 pyr_pkt[] = { 0x86, 0x81 };
  u_8 *ptr, *pkt;
  int i, j;

  rq[4] = (id & 0xff000000) >> 24;
  rq[5] = (id & 0x00ff0000) >> 16;
  rq[6] = (id & 0x0000ff00) >> 8;
  rq[7] = (id & 0x000000ff) >> 0;

  crc = 0xffff;
  for (i = 3; i < 14; ++i) {
    crc ^= rq[i];
    for (j = 0; j < 8; ++j) {
      if (crc & 1) {
        crc >>= 1;
        crc ^= 0xa001;
      } else {
        crc >>= 1;
      }
    }
  }
  rq[14] = (crc & 0x00ff) >> 0;
  rq[15] = (crc & 0xff00) >> 8;

  ptr = buf;
  pkt = 
  ptr = store_data(ptr, pyr_head, sizeof(pyr_head), 0);
  ptr = store_data(ptr, pyr_pkt, sizeof(pyr_pkt), 0);

  ptr = store_data(ptr, rq, sizeof(rq), 1);
  crc = 0x0;
  for (i = 0; i < (ptr - pkt); ++i) {
    crc ^= ((unsigned short)pkt[i]) << 8;
    for (j = 0; j < 8; j++) {
      if (crc & 0x8000) {
        crc <<= 1;
        crc ^= 0x1021;
      } else {
        crc <<= 1;
      }
    }
  }
  crc |= 0x8080;
  *ptr++ = (crc & 0x00ff) >> 0;
  *ptr++ = (crc & 0xff00) >> 8;
  *ptr++ = 0x3;
  return ptr - buf;
}

void usage(const char *exe)
{
  fprintf(stdout, "usage: %s <-i id> <-p port|-c port> <server:port>\n", exe);
}

static int prepare_socket(struct sockaddr_in *sa, int do_connect)
{
  int sock;

  sock = socket(AF_INET, SOCK_STREAM, 0);
  if (sock < 0) {
    die(-ERR_NET_INIT, "socket failed: %s\n", strerror(errno));
  }

  if (do_connect) {
    if (connect(sock, (struct sockaddr *)sa, sizeof(*sa)) < 0) {
      die(-ERR_NET_INIT, "connect to %s:%u failed: %s\n", inet_ntoa(sa->sin_addr), ntohs(sa->sin_port), strerror(errno));
    }
  } else {
    if (bind(sock, (struct sockaddr *)sa, sizeof(*sa)) < 0) {
      die(-ERR_NET_INIT, "socket bind failed: %s\n", strerror(errno));
    }
    if (listen(sock, 16) < 0) {
      die(-ERR_NET_INIT, "socket listen failed: %s\n", strerror(errno));
    }
  }

  fcntl(sock, F_SETFL, O_NONBLOCK);

  return sock;
}

void fill_addr(const char *addr_text, struct sockaddr_in *sa)
{
	char *host;
	const char *p;
	struct hostent *hostent;

	p = strchr(addr_text, ':');
	if (p == 0) {
		die(ERR_OPTIONS, "invalid address \"%s\" (must be \"addr:port\")\n", addr_text);
	}
	host = alloca(p - addr_text + 1);
	memcpy(host, addr_text, p - addr_text);
	host[p - addr_text] = '\0';
	p += 1;
	sa->sin_port = htons(strtoul(p, 0, 0));
  
  if (sa->sin_port == 0 && *p != '0') {
    die(ERR_OPTIONS, "invalid port specification \"%s\"\n", p);
  }
	
	hostent = gethostbyname(host);
	if (hostent == 0) {
		if (errno == 0) {
			die(ERR_NET_INIT, "gethostbyname(\"%s\") failed\n", host);
		} else {
    	die(ERR_NET_INIT, "gethostbyname(\"%s\") failed: %s\n", host, strerror(errno));
    }
 	}
	bcopy((char *)hostent->h_addr, (char *)&sa->sin_addr.s_addr, hostent->h_length);
}

size_t transfer(int *in, int *out, char *buf, size_t sz, size_t max_sz, fd_set *rfds, fd_set *wfds, size_t *rx_count, size_t *tx_count)
{
  size_t done;

  if (in && *in >= 0 && FD_ISSET(*in, rfds)) {
    if (max_sz > sz) {
      done = read(*in, buf + sz, max_sz - sz);
      if (done < 1) {
        die(-ERR_NET_EXCH, "socket(%d) closed by other side\n", *in);
      }
#if defined(DEBUG) && DEBUG
      if (done > 0) {
        slog(LOG_DEBUG, "read(%d,%zu) = %zu\n", *in, max_sz - sz, done);
        hexdump(buf + sz, done);
      }
#endif
      if (rx_count != 0) {
        *rx_count += done;
      }
      sz += done;
    }
  }
  if (out && *out >= 0 && FD_ISSET(*out, wfds) && sz > 0) {
    done = write(*out, buf, sz);
    if (done < 0) {
      if (errno != EAGAIN && errno != EWOULDBLOCK) {
        die(-ERR_NET_EXCH, "error sending to socket(%u): %s\n", *out, strerror(errno));
      }
    } else {
#if defined(DEBUG) && DEBUG
      if (done > 0) {
        slog(LOG_DEBUG, "write(%d,%zu) = %zu\n", *out, sz, done);
        hexdump(buf, done);
      }
#endif
      if (tx_count != 0) {
        *tx_count += done;
      }
      if (done >= sz) {
        sz = 0;
      } else {
        memmove(buf, buf + done, sz - done);
        sz -= done;
      }
    }
  }
  return sz;
}

#undef max
#define max(x,y) ((x) > (y) ? (x) : (y))

int main(int argc, char **argv)
{
  const char optstring[] = "hi:kp:c:t:";
  const char *p;

  int i;
  struct sockaddr_in srv_sa;
  struct hostent *hostent;
  char *server_addr;
  time_t old_call,new_call;

  struct sockaddr_in listen_sa;
  struct sockaddr_in accept_sa;
  struct sockaddr_in connect_sa;
  socklen_t accept_sa_len;

  int sock_out, sock_listen, sock_in, sock_tmp;

  int *sock_tx, *sock_rx;

  u_32 id = 0xbf198245;
  int id_set = 0;

  fd_set rfds, wfds;
  struct timeval tv;
  int retval;
  int nfds;
  int time_out_no_io=300;

  char buf_in[4096], buf_out[4096];
  size_t in_sz, out_sz;

  int logged_in = 0;

  bzero((char *) &srv_sa, sizeof(srv_sa));
  srv_sa.sin_family = AF_INET;

  bzero((char *) &listen_sa, sizeof(listen_sa));
  listen_sa.sin_family = AF_INET;

  bzero((char *) &connect_sa, sizeof(connect_sa));
  connect_sa.sin_family = AF_INET;

  while ((i = getopt(argc, argv, optstring)) >= 0) {
    switch (i) {
      case 't':
        time_out_no_io = strtoul(optarg, 0, 0);
        if (time_out_no_io == 0 && *optarg != '0') {
          die(ERR_OPTIONS, "error: invalid time_out_no_io specified\n");
        }
        break;
      case 'i':
        id = strtoul(optarg, 0, 0);
        if (id == 0 && *optarg != '0') {
          die(ERR_OPTIONS, "error: invalid id specified\n");
        }
        id_set = 1;
        break;
      case 'p':
        listen_sa.sin_port = htons(strtoul(optarg, 0, 0));
        if (listen_sa.sin_port == 0 && optarg[0] != '0') {
          die(ERR_OPTIONS, "error: invalid port value\n");
        }
        break;
      case 'c':
				p = strchr(optarg, ':');
				if (p == 0) {
					connect_sa.sin_port = htons(strtoul(optarg, 0, 0));
					inet_aton("127.0.0.1", &connect_sa.sin_addr);
				} else {
					fill_addr(optarg, &connect_sa);
				}
        break;
      default:
        usage(argv[0]);
        exit(0);
        break;
    }
  }

  if (optind >= argc) {
    usage(argv[0]);
    exit(0);
  }

  if (id_set == 0) {
    die(ERR_OPTIONS, "error: no id specified\n");
  }
  if (listen_sa.sin_port == 0 && connect_sa.sin_port == 0) {
    die(ERR_OPTIONS, "error: invalid or no port specified\n");
  }

	fill_addr(argv[optind], &srv_sa);

  sock_in = -1;
  sock_listen = -1;

  if (listen_sa.sin_port != 0) {
    sock_listen = prepare_socket(&listen_sa, 0);
    slog(LOG_INFO, "local=%s:%u\n", inet_ntoa(listen_sa.sin_addr), ntohs(listen_sa.sin_port));
  } else {
    sock_in = prepare_socket(&connect_sa, 1);
    slog(LOG_INFO, "local=%s:%u\n", inet_ntoa(connect_sa.sin_addr), ntohs(connect_sa.sin_port));
  }
  slog(LOG_INFO, "server=%s:%u\n", inet_ntoa(srv_sa.sin_addr), ntohs(srv_sa.sin_port));
  slog(LOG_INFO, "id=0x%08x\n", id);

  sock_out = prepare_socket(&srv_sa, 1);

  in_sz = 0;
  out_sz = 0;
  logged_in = 0;

  if (sock_in < 0) {
    slog(LOG_INFO, "starting loop: sock_out=%d, sock_listen=%d\n", sock_out, sock_listen);
  } else {
    slog(LOG_INFO, "starting loop: sock_out=%d, sock_in=%d\n", sock_out, sock_in);
  }

  while (1) {
    tv.tv_sec = 10;
    tv.tv_usec = 0;

    FD_ZERO(&rfds);
    FD_ZERO(&wfds);

    if (sock_listen >= 0) {
      FD_SET(sock_listen, &rfds);
    }
    if (out_sz < sizeof(buf_out)) {
      FD_SET(sock_out, &rfds);
    }
    if (in_sz > 0) {
      FD_SET(sock_out, &wfds);
    }
    if (sock_in >= 0) {
      if (in_sz < sizeof(buf_in)) {
        FD_SET(sock_in, &rfds);
      }
      if (out_sz > 0) {
        FD_SET(sock_in, &wfds);
      }
    }
    nfds = max(sock_listen, max(sock_in, sock_out));
 
    retval = select(nfds + 1, &rfds, &wfds, 0, &tv);
    if (retval > 0) {
      if (sock_listen >= 0 && FD_ISSET(sock_listen, &rfds)) {
        accept_sa_len = sizeof(accept_sa);
        sock_tmp = accept(sock_listen, (struct sockaddr *)&accept_sa, &accept_sa_len);
        if (sock_in < 0) {
          if (sock_tmp < 0) {
            die(-ERR_NET_EXCH, "accept failed: %s\n", strerror(errno));
          }
          sock_in = sock_tmp;
          out_sz = 0;
          slog(LOG_INFO, "accepted connection from: %s:%u (sock_in=%d)\n", inet_ntoa(accept_sa.sin_addr), htons(accept_sa.sin_port), sock_in);
        } else if (sock_tmp >= 0) {
          close(sock_tmp);
          slog(LOG_INFO, "dropped connection from: %s:%u (sock=%d)\n", inet_ntoa(accept_sa.sin_addr), htons(accept_sa.sin_port), sock_tmp);
        }
      }
      if (logged_in) {
        out_sz = transfer(&sock_out, &sock_in, buf_out, out_sz, sizeof(buf_out), &rfds, &wfds, &srv_total_rx, &clnt_total_tx);
        in_sz = transfer(&sock_in, &sock_out, buf_in, in_sz, sizeof(buf_in), &rfds, &wfds, &clnt_total_rx, &srv_total_tx);
      } else {
        const int serv_rq_sz = 39;

        out_sz = transfer(&sock_out, 0, buf_out, out_sz, sizeof(buf_out), &rfds, &wfds, &srv_total_rx, &clnt_total_tx);
        if (out_sz >= serv_rq_sz && buf_out[0] == 0x2 && buf_out[serv_rq_sz-1] == 0x3) {
          slog(LOG_INFO, "received request to login from server\n");
          memmove(buf_out, buf_out + serv_rq_sz, out_sz - serv_rq_sz);
          out_sz -= serv_rq_sz;
          in_sz = get_server_reply(id, buf_in);
          logged_in = 1;
          slog(LOG_INFO, "sent login to server\n");
        }
      }
    } else if (retval < 0) {
      die(-ERR_NET_EXCH, "select error: %s\n", strerror(errno));
    }
    if((out_sz!=0) || (in_sz!=0))
    {
	old_call=time(0);
    }
    else
    {
	if(   ( time(0)-old_call ) > time_out_no_io ) // have to change to argv[]!!!
	{
            die(-ERR_NET_EXCH, "IO wait data exchange timeout expired: %d seconds\n", time_out_no_io);
	}
    }
  }

  return 0;
}
