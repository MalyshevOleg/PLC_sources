# Package: FAKEROOT
FAKEROOT_VERS = 1.18.4
FAKEROOT_EXT  = tar.bz2
FAKEROOT_SITE = http://ftp.debian.org/debian/pool/main/f/fakeroot
FAKEROOT_PDIR = utils/fakeroot

FAKEROOT_CONFIG_VARS = CFLAGS=-O2

FAKEROOT_CONFIG_OPTS = \
    --prefix=$(TARGET_DIR) \
    --bindir=$(BINARIES_DIR)/x86/fakeroot \
    --libdir=$(BINARIES_DIR)/x86/fakeroot

$(eval $(call create-common-vars,fakeroot,FAKEROOT,-))
FAKEROOT_SRC  = fakeroot_$(FAKEROOT_VERS).orig.$(FAKEROOT_EXT)
$(eval $(call create-common-targs,fakeroot,FAKEROOT))
$(eval $(call create-install-targs,fakeroot,FAKEROOT))


FAKEROOT_INSTALL_TARGET = install-strip
