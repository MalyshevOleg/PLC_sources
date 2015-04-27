#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <sys/types.h>
#include <dirent.h>
#include <regex.h>
#include <getopt.h>
#include <errno.h>


char *xstrdup(const char *s, int len)
{
	char *r;
	int s_len;

	s_len = strlen(s);
	if (len < 0 || s_len <= len) {
		r = strdup(s);
		if (r == 0) {
			err(1, "xstrdup");
		}
	} else {
		r = malloc(len + 1);
		if (r == 0) {
			err(1, "xstrdup");
		}
		memcpy(r, s, len);
		r[len] = '\0';
	}
	return r;
}

char *xstrcat(const char *s1, const char *s2)
{
	char *r;
	r = malloc(strlen(s1) + strlen(s2) + 1);
	if (r == 0) {
		err(1, "xstrcat");
	}
	strcpy(r, s1);
	strcat(r, s2);
	return r;
}

char *xmergepath(const char *path, const char *fn)
{
	char *p1, *p2;
	if (strlen(path) > 0 && path[strlen(path)] != '/') {
		p1 = xstrcat(path, "/");
		p2 = xstrcat(p1, fn);
		free(p1);
	} else {
		p2 = xstrcat(path, fn);
	}
	return p2;
}

int xfind(const char *path, const char *fn, int type, int print)
{
	struct dirent **files;
	int n, r;
	regex_t reg;

	if (regcomp(&reg, fn, REG_EXTENDED) < 0) {
		err(2, "regcomp: %s", fn);
	}

	r = 0;
	n = scandir(path, &files, 0, alphasort);
	if (n < 0) {
		err(2, "scandir: %s", path);
	} else {
		while (n--) {
			if (type == 0 || type == files[n]->d_type) {
				if ((r == 0 || print) && regexec(&reg, files[n]->d_name, 0, 0, 0) == 0) {
					if (print) {
						printf("%s\n", files[n]->d_name);
					}
					r = 1;
				}
			}
			free(files[n]);
		}
		free(files);
	}

	regfree(&reg);

	return r;
}

int xgrep(const char *path, const char *fn, const char *str, int nocase, int print)
{
	FILE *f;
	regex_t reg;
	char *ffn;
	char buf[1024];
	int r;

	ffn = xmergepath(path, fn);

	f = fopen(ffn, "rt");
	if (f == 0) {
		err(2, "fopen: %s", ffn);
	}
	free(ffn);

	if (regcomp(&reg, str, REG_EXTENDED | (nocase ? REG_ICASE : 0)) < 0) {
		err(2, "regcomp: %s", str);
	}

	r = 0;
	while (!feof(f)) {
		fgets(buf, sizeof(buf), f);
		if (regexec(&reg, buf, 0, 0, 0) == 0) {
			r = 1;
			if (print) {
				printf("%s", buf);
			} else {
				break;
			}
			break;
		}
	}
	regfree(&reg);
	
	return r;
}

static int is_ep(const struct dirent *d)
{
	const char *ep_pat = "^ep_[0-9a-fA-F]+$";
	regex_t reg;
	int r;

	if (regcomp(&reg, ep_pat, REG_EXTENDED) < 0) {
		err(2, "regcomp: %s", ep_pat);
	}

	r = regexec(&reg, d->d_name, 0, 0, 0);
	if (r < 0) {
		err(2, "regexec");
	}

	regfree(&reg);

	return (r != REG_NOMATCH);
}

int xintf_interrupt(const char *path)
{
	struct dirent **files;
	int n, r;
	char *ep;

	if (xfind(path, "ttyUSB[0-9]+", 0, 0) == 0) {
		return 0;
	}

	n = scandir(path, &files, is_ep, alphasort);
	if (n < 0) {
		err(2, "scandir: %s", path);
	} else {
		r = 0;
		while (n--) {
			if (!r) {
				ep = xmergepath(path, files[n]->d_name);
				if (xfind(ep, "type", 0, 0) && xgrep(ep, "type", "interrupt", 1, 0)) {
					r = 1;
				}
				free(ep);
			}
			free(files[n]);
		}
		free(files);
	}
	
	return r;
}

int main(int argc, char **argv)
{
	char *devpath, *p, *root;
	int num, i, inum;

	int cmd_add = 0, cmd_delete = 0;
	int opt_nosys_prefix = 0;
	int opt;

	while ((opt = getopt(argc, argv, "ads")) >= 0) {
		switch (opt) {
		case 'a':
			if (cmd_delete) {
				errx(1, "options -a and -d cannot be specified");
			}
			if (cmd_add) {
				errx(1, "option -a specified many times");
			}
			cmd_add = 1;
			break;
		case 'd':
			if (cmd_add) {
				errx(1, "options -a and -d cannot be specified");
			}
			if (cmd_delete) {
				errx(1, "option -d specified many times");
			}
			cmd_delete = 1;
			break;
		case 's':
			opt_nosys_prefix = 1;
			break;
		}
	}


	if (optind >= argc) {
		exit(1);
	}	

	if (opt_nosys_prefix || strncmp(argv[optind], "/sys", 4) == 0) {
		devpath = xstrdup(argv[optind], -1);
	} else {
		devpath = xmergepath("/sys", argv[optind]);
	}

	if (cmd_delete) {
		err(1, "-d not yet implemented");
	}

	p = strstr(devpath, "/ttyUSB");
	if (p == 0) {
		errx(1, "%s is not ttyUSB device path", devpath);
	}

	*p = '\0';

	p = strrchr(devpath, '.');
	if (p == 0) {
		errx(1, "invalid interface number");
	}
	root = xstrdup(devpath, p - devpath);
	num = atoi(p + 1);

	p = alloca(strlen(root) + 11);
	inum = -1;
	for (i = num ; i >= 0; --i) {
		snprintf(p, strlen(root) + 11, "%s.%d", root, i);
		if (xintf_interrupt(p)) {
			inum = i;
		}
	}
	if (inum >= 0) {
		snprintf(p, strlen(root) + 11, "%s.%d", root, inum);
		xfind(p, "ttyUSB[0-9]+", 0, 1);
	}
}
