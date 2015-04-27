#! /bin/sh
#
# This script
# 1) tunes sudopath macro in config/hostmacros.mk
# 2) checks for installed packages on the host 
#

BASEDIR=$1

# Packages required for Ubuntu host
UPKGLIST="libmpfr-dev libgmp3-dev ^xutils-dev texinfo$ \
 bison$ ^flex$ ^libtool$ gawk$ ^bash$ zlib1g-dev liblzo2-dev \
 autoconf$ ^g\\+\\+$ libncurses5-dev libglib2.0-dev ^uuid-dev \
 ^gettext$ libarchive-zip-perl"

# Packages required for Slackware host
SPKGLIST="lndir-* texinfo-* bison-* flex-* libtool-* \
 gawk-* bash-* zlib-* lzo-* autoconf-* gcc-g++-* ncurses-* \
 glib2-2* util-linux-* gettext-tools-*"

PACK2INSTALL=

EXE_LIST="rm cp mv cat echo cut paste ln sed awk grep date mkdir \
 tee touch chmod find xargs sudo wget lndir install \
 tar unzip bzcat zcat gzip patch gcc strip /sbin/mkfs.cramfs"

EXE2INSTALL=

distro=`$BASEDIR/scripts/distroname.sh`
sudoenv=1

if [ -z "$distro" ] ; then
  distro=ubuntu
fi

checkexe()
{
    for item in $EXE_LIST; do
	printf "Checking for %-12s" $item
	type -P $item || { echo "============= Not found !"; }
    done
}

checkUpack()
{
    for item in $UPKGLIST; do
	itemname=$(echo $item | sed 's/\^//;s/\$//;s/\\//g')
	printf "Package: %-16s" $itemname
	REZ=$(aptitude -F %c search $item | sed '1{s/^\(.\)\(.*\)/\1/;q}')
	if [ "$REZ" = "i" ]; then
	    echo "OK"
	else
	    echo "Not found"
	    PACK2INSTALL="$itemname $PACK2INSTALL"
	fi
    done

    if [ -n "$PACK2INSTALL" ]; then
	echo
	echo "Please install the following packages:"
	echo "  $PACK2INSTALL"
    fi

    SHELLTARGET=$(ls -l /bin/sh | sed -e 's/.*bash$/bash/')
    if [ "$SHELLTARGET" != "bash" ]; then
	echo "You MUST have bash as default shell. Please run: "
	echo "  sudo dpkg-reconfigure dash"
	echo "and make /bin/sh pointing to bash"
	echo "  sudo rm /bin/sh"
	echo "  sudo ln -s bash /bin/sh"
    fi
}

checkSpack()
{
    for item in $SPKGLIST; do
	itemname=$(echo $item | sed 's/-\*//')
	printf "Package: %-16s" $itemname
	if [ -f /var/adm/packages/$item ]; then
	    echo "OK"
	else
	    echo "Not found"
	    PACK2INSTALL="$itemname $PACK2INSTALL"
	fi
    done

    if [ -n "$PACK2INSTALL" ]; then
	echo
	echo "Please install the following packages (run the following):"
	echo "  sudo apt-get install $PACK2INSTALL"
    fi

    SHELLTARGET=$(ls -l /bin/sh | sed -e 's/.*bash$/bash/')
    if [ "$SHELLTARGET" != "bash" ]; then
	echo "You MUST have bash as default shell. Please "
	echo "make /bin/sh pointing to bash"
	echo "  sudo rm /bin/sh"
	echo "  sudo ln -s bash /bin/sh"
    fi
}

case "$distro" in
  slamd64 | [Ss]lackware)
    sudoenv=0
    checkSpack
    ;;
  [uU]buntu)
    checkUpack
    ;;
  *)
    ;;
esac

checkexe

if [ $sudoenv -eq 1 ] ; then
    sed -i -e "/Ubuntu/{n;s/^\(#\?\)sudo/sudo/}" \
      -e "/Slackware/{n;s/^\(#\?\)sudo/#sudo/}" ${BASEDIR}/config/hostmacros.mk
else
    sed -i -e "/Slackware/{n;s/^\(#\?\)sudo/sudo/}" \
      -e "/Ubuntu/{n;s/^\(#\?\)sudo/#sudo/}" ${BASEDIR}/config/hostmacros.mk
fi
