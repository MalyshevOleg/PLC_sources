# Package: BINUTILS
#BINUTILS_VERS = 2.18.50.0.5
BINUTILS_VERS = 2.19.1
BINUTILS_EXT  = tar.bz2
#BINUTILS_SITE = http://kernel.org/pub/linux/devel/binutils
BINUTILS_SITE = ftp://ftp.gnu.org/gnu/binutils
BINUTILS_PDIR = toolchain/binutils

ifeq "$(MACH)" "at91"
SOFT_FLOAT = --with-float=soft
else ifeq "$(MACH)" "s3c2410"
SOFT_FLOAT = --with-float=soft
else ifeq "$(MACH)" "s3c"
SOFT_FLOAT = --with-float=soft
else ifeq "$(MACH)" "qemu"
SOFT_FLOAT = --with-float=soft
else
SOFT_FLOAT = --with-fp=vfp
endif

BINUTILS_CONFIG_VARS = CC=$(HOST_CC) CFLAGS=-O2

BINUTILS_MAKE_VARS = MAKEINFO=true


BINUTILS_CONFIG_OPTS = \
    --build=$(HOST_CPU) \
    --host=$(HOST_CPU) \
    --target=$(TARGET) \
    --prefix=$(TARGET_DIR) \
    MAKEINFO=missing \
    --infodir=$(TARGET_DIR)/share/info \
    --mandir=$(TARGET_DIR)/share/man \
    --libdir=$(TARGET_DIR)/$(TARGET)/lib \
    --with-sysroot=$(TARGET_DIR)/$(TARGET) \
    $(SOFT_FLOAT) \
    --disable-werror \
    --disable-nls \
    --disable-multilib

BINUTILS_INSTALL = $(SUDO)
BINUTILS_POSTHOSTINST = $(call autoclean,binutils-dirclean)

$(eval $(call create-common-defs,binutils,BINUTILS,-))
