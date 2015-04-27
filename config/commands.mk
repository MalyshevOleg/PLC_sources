# Usefull commands with verbosity options
#
HOST_CC=gcc
BZCAT=bzcat
ZCAT=zcat
SED=sed
AWK=awk
CONFIGURE=configure $(VERBOSE_CONF)
PATCH=patch $(VERBOSE_PATCH)
MAKE=make $(VERBOSE_MAKE)
TAR=tar $(VERBOSE_TAR)
UNZIP=unzip $(VERBOSE_UNZIP)
TAR_OPTS=-cf
UNTAR_OPTS=-xf
CP=cp -a $(VERBOSE_COPY)
WGET=wget --passive-ftp -nc $(VERBOSE_WGET) -t 2 -T 30
MAKEPKG=makepkg -c n -l y
ifeq "$(USE_SUDO)" "TRUE"
SUDO=sudo
else
SUDO=
endif